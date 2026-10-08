import '../models/email_summary.dart';
import '../models/rule.dart';
import 'llm_client.dart';
import 'prompts.dart' as prompts;

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
