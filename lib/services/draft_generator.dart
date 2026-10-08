import '../models/draft_record.dart';
import '../models/email_summary.dart';
import '../models/rule.dart';
import 'llm_client.dart';
import 'prompts.dart' as prompts;

/// 已发送状态的草稿（含手工标注）转成伪 Sent 邮件，供学习 / 线程上下文使用。
///
/// messageId 用 `draft:<id>` 前缀，与真实邮件的 Message-ID 空间隔离；
/// inReplyTo 指向所回复的来信，保证与来信配对 / 线程聚类成立。
EmailSummary? draftAsSentEmail(DraftRecord d, String senderAddress) {
  final text = (d.finalSentText ?? '').trim();
  if (text.isEmpty) return null;
  return EmailSummary(
    messageId: 'draft:${d.id}',
    subject: 'Re: ${d.subject}',
    fromAddress: senderAddress,
    toAddresses: [d.toAddress],
    date: (d.sentAt ?? DateTime.now()).toIso8601String(),
    folder: 'Sent',
    bodyText: d.finalSentText!,
    inReplyTo: d.emailMessageId,
  );
}

/// 把「已发送 / 手工标注已发送」的草稿补进线程上下文。
///
/// 通过本应用发送的草稿正文已由 SMTP appendToSent 写入 Sent，本地缓存刷新后
/// 就在 [conversationMessages] 里；注入是为了补上「刚发送、缓存尚未同步」的
/// 窗口，以及手工标注（不会出现在 IMAP Sent）的记录。正文与现有往来完全
/// 一致的视为已同步，跳过避免重复；未发送 / 已丢弃的草稿不参与。
List<EmailSummary> sentDraftsAsThreadPeers({
  required List<DraftRecord> drafts,
  required Set<String> conversationMessageIds,
  required List<EmailSummary> conversationMessages,
  required String Function(String accountId) resolveSender,
}) {
  final existingBodies = conversationMessages
      .map((m) => m.bodyText.trim())
      .where((t) => t.isNotEmpty)
      .toSet();
  // 引用头 + 归一化主题匹配：列表阶段真实邮件 bodyText 尚未回填时，
  // 也能识别出该草稿对应的已发邮件已经同步，避免重复注入。
  final repliedAnchors = conversationMessages
      .where((m) => m.inReplyTo != null && m.inReplyTo!.isNotEmpty)
      .map((m) => '${m.inReplyTo}|${m.normalizedSubject}')
      .toSet();
  final result = <EmailSummary>[];
  for (final d in drafts) {
    final sent = d.status == DraftStatus.sentUnmodified ||
        d.status == DraftStatus.sentEdited ||
        d.status == DraftStatus.sentManually;
    if (!sent || !conversationMessageIds.contains(d.emailMessageId)) continue;
    final text = (d.finalSentText ?? '').trim();
    if (text.isEmpty ||
        existingBodies.contains(text) ||
        repliedAnchors
            .contains('${d.emailMessageId}|${EmailSummary.normalizeSubject(d.subject)}')) {
      continue;
    }
    final pseudo = draftAsSentEmail(d, resolveSender(d.accountId));
    if (pseudo == null) continue;
    result.add(pseudo);
    existingBodies.add(text);
  }
  return result;
}

/// 草稿生成器：严格「只用回复规则」起草。
class DraftGenerator {
  DraftGenerator({required this.llm});

  final LlmClient llm;

  /// 生成草稿。
  ///
  /// [rules] 是本次注入的启用规则（由调用方选定，通常为全部启用规则）；
  /// [threadPeers] 是同线程的历史往来（仅用于压缩成上下文摘要，
  /// 其原文不会进入规则体系之外的引用）。
  Future<DraftGenerationResult> generate({
    required EmailSummary email,
    required List<Rule> rules,
    required List<EmailSummary> threadPeers,
    required String outputLanguage,
  }) async {
    if (rules.isEmpty) {
      throw StateError('规则库为空，请先从历史邮件、知识库或自定义 Prompt 生成回复规则');
    }

    // 线程上下文压缩：超过 3 封时让 LLM 摘要，避免上下文过长。
    var threadContext = '';
    if (threadPeers.isNotEmpty) {
      if (threadPeers.length <= 3) {
        threadContext =
            threadPeers.map((e) => e.toLearningText()).join('\n');
      } else {
        final digest = await llm.chat([
          LlmMessage.user(prompts.threadDigestPrompt(
              threadPeers.map((e) => e.toLearningText()).join('\n'))),
        ]);
        threadContext = digest.content;
      }
    }

    final incomingEmail = '发件人：${email.fromAddress}\n'
        '时间：${email.date}\n'
        '主题：${email.subject}\n'
        '正文：\n${email.bodyText.isEmpty ? email.snippet : email.bodyText}';

    final rulesText = rules
        .map((r) => '${r.id} | [${r.category.label}] ${r.content}')
        .join('\n');

    final result = await llm.chat(
      [
        LlmMessage.user(prompts.draftPrompt(
          incomingEmail: incomingEmail,
          threadContext: threadContext,
          rulesText: rulesText,
          language: outputLanguage,
        )),
      ],
      temperature: 0.4,
    );

    return DraftGenerationResult(
      draftText: result.content.trim(),
      usedRuleIds: rules.map((r) => r.id).toList(),
      threadContextDigest: threadContext.length > 2000
          ? threadContext.substring(0, 2000)
          : threadContext,
    );
  }
}

class DraftGenerationResult {
  const DraftGenerationResult({
    required this.draftText,
    required this.usedRuleIds,
    required this.threadContextDigest,
  });

  final String draftText;
  final List<String> usedRuleIds;
  final String threadContextDigest;
}
