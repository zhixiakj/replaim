import 'package:diff_match_patch/diff_match_patch.dart';

import '../models/draft_record.dart';
import '../models/rule.dart';
import 'json_extract.dart';
import 'llm_client.dart';
import 'prompts.dart' as prompts;
import 'rule_store.dart';

/// 反馈学习器：草稿发送后对比「原始草稿 vs 实际发送稿」，
/// 分析用户修改并优化回复规则（自动应用，来源记为 draft_feedback）。
class FeedbackLearner {
  FeedbackLearner({required this.llm, required this.store});

  final LlmClient llm;
  final RuleStore store;

  /// 无实质修改（忽略空白差异）。
  static bool isUnmodified(String original, String sent) =>
      _normalize(original) == _normalize(sent);

  static String _normalize(String s) =>
      s.replaceAll('\r\n', '\n').split('\n').map((l) => l.trim()).join('\n').trim();

  /// 生成人类可读的 diff 摘要（供 prompt 与草稿记录）。
  static String diffSummary(String original, String sent) {
    final diffs = diff(original.replaceAll('\r\n', '\n'),
        sent.replaceAll('\r\n', '\n'));
    // cleanupSemantic 把字符级碎片合并成语义块，否则摘要不可读。
    cleanupSemantic(diffs);
    final buf = StringBuffer();
    for (final d in diffs) {
      switch (d.operation) {
        case DIFF_INSERT:
          buf.writeln('＋ ${_oneLine(d.text)}');
        case DIFF_DELETE:
          buf.writeln('－ ${_oneLine(d.text)}');
        default:
          break;
      }
    }
    final s = buf.toString().trim();
    return s.isEmpty ? '（无文本差异）' : s;
  }

  static String _oneLine(String s) =>
      s.replaceAll('\n', ' ⏎ ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// 学习草稿修改：返回应记录到草稿上的信息。
  ///
  /// 未修改时不调用 LLM，仅返回正反馈信号。
  Future<DraftFeedbackResult> learn({
    required DraftRecord draft,
    required String finalSentText,
  }) async {
    if (isUnmodified(draft.originalDraft, finalSentText)) {
      await store.markStats(draft.usedRuleIds,
          used: true, keptUnchanged: true);
      return DraftFeedbackResult(wasModified: false, ruleUpdates: const []);
    }

    await store.markStats(draft.usedRuleIds, used: true, edited: true);

    final usedRules = draft.usedRuleIds
        .map(store.findById)
        .whereType<Rule>()
        .toList();
    final rulesText = usedRules
        .map((r) => '${r.id} | [${r.category.label}] ${r.content}')
        .join('\n');
    final diffText = diffSummary(draft.originalDraft, finalSentText);

    final raw = await llm.chatJson([
      LlmMessage.user(prompts.draftFeedbackPrompt(
        originalDraft: draft.originalDraft,
        finalSent: finalSentText,
        rulesText: rulesText,
        diffSummary: diffText,
      )),
    ]);
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final changeSummary = readStr(map, ['change_summary', 'changeSummary']) ?? '';

    final operations = (map['operations'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final updates = <RuleUpdateRecord>[];
    for (final op in operations) {
      final action = readStr(op, ['op'])?.toLowerCase();
      final targetId = readStr(op, ['target_id', 'targetId']);
      final content = readStr(op, ['content']);
      final reason = readStr(op, ['reason']) ?? '';
      switch (action) {
        case 'add' when content != null:
          final category = RuleCategory.fromName(readStr(op, ['category']));
          final rule = await store.add(newRuleFromGeneration(
            type: RuleSourceType.draftFeedback,
            generatedBy: llm.generatedBy,
            details: {
              'draft_id': draft.id,
              'email_message_id': draft.emailMessageId,
              'change_summary': changeSummary,
              'reason': reason,
            },
            content: content,
            category: category,
          ));
          updates.add(RuleUpdateRecord(
              action: 'add', summary: '$reason（新规则）', ruleId: rule.id));
        case 'update' when targetId != null && content != null:
          final existing = store.findById(targetId);
          if (existing == null) continue;
          await store.updateContent(
            targetId,
            content,
            reason: '草稿修改反馈：$reason',
            newSource: RuleSource(
              type: RuleSourceType.draftFeedback,
              createdAt: DateTime.now(),
              generatedBy: llm.generatedBy,
              details: {
                'draft_id': draft.id,
                'change_summary': changeSummary,
                'reason': reason,
                'previous_source': existing.source.toMap(),
              },
            ),
          );
          updates.add(
              RuleUpdateRecord(action: 'update', summary: reason, ruleId: targetId));
        case 'disable' when targetId != null:
          await store.setEnabled(targetId, false);
          updates.add(
              RuleUpdateRecord(action: 'disable', summary: reason, ruleId: targetId));
      }
    }
    return DraftFeedbackResult(
      wasModified: true,
      ruleUpdates: updates,
      diffSummary: diffText,
      changeSummary: changeSummary,
    );
  }
}

class DraftFeedbackResult {
  const DraftFeedbackResult({
    required this.wasModified,
    required this.ruleUpdates,
    this.diffSummary,
    this.changeSummary = '',
  });

  final bool wasModified;
  final List<RuleUpdateRecord> ruleUpdates;
  final String? diffSummary;

  /// LLM 概括的用户修改摘要。
  final String changeSummary;
}
