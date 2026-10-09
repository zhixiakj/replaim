
import '../models/email_summary.dart';
import '../models/rule.dart';
import 'app_log.dart';
import 'json_extract.dart';
import 'llm_client.dart';
import 'prompts.dart' as prompts;
import 'rule_store.dart';

/// 学习路径的规范线程键：回复取 References 链根 Message-ID，
/// 线程根（无引用头）取自身 Message-ID——两者天然一致。
/// 不用 [EmailSummary.threadKey]：它对线程根会退化成归一化主题，
/// 与回复的键对不上，导致客户来信与我方回复被拆进不同线程/批次。
String canonicalThreadKey(EmailSummary e) {
  final root = e.referencesIds.isNotEmpty ? e.referencesIds.first : e.inReplyTo;
  if (root != null && root.isNotEmpty) return root;
  return e.messageId.isNotEmpty ? e.messageId : e.normalizedSubject;
}

/// 收发配对：从收件箱邮件中只保留与任一发件同线程的来信（问→答成对学习）。
///
/// 匹配依据：来信 Message-ID 出现在发件的 References/In-Reply-To 中；
/// 发件缺引用头时回落到归一化主题相等（部分客户端只靠主题串线程）。
/// 订阅、通知等没有对应发件的来信全部丢弃。
List<EmailSummary> pairIncomingWithSent({
  required List<EmailSummary> sent,
  required List<EmailSummary> inbox,
}) {
  final referencedIds = <String>{};
  final subjectFallbacks = <String>{};
  for (final s in sent) {
    referencedIds.addAll(s.referencesIds);
    final irt = s.inReplyTo;
    if (irt != null && irt.isNotEmpty) referencedIds.add(irt);
    if (s.referencesIds.isEmpty && (irt == null || irt.isEmpty)) {
      subjectFallbacks.add(s.normalizedSubject);
    }
  }
  return inbox
      .where((m) =>
          referencedIds.contains(m.messageId) ||
          subjectFallbacks.contains(m.normalizedSubject))
      .toList();
}

/// 规则生成器：三个来源（历史邮件 / 知识库 / 用户 prompt）+ 合并策略。
///
/// 防旧覆盖新的机制（历史邮件来源）：
/// 1. 已消费邮件记录在 learn_state，绝不重复学习；
/// 2. 批内按时间升序（旧→新）分批处理；
/// 3. 合并时「新规则与旧规则冲突 → 新规则胜出」（新规则来自更新的邮件），
///    旧规则内容进 history 保留，不物理删除。
class RuleGenerators {
  RuleGenerators({required this.llm, required this.store});

  final LlmClient llm;
  final RuleStore store;

  /// 每批邮件材料的字符预算（约等于 4~6k token，留足输出空间）。
  static const _emailBatchChars = 10000;

  /// 学习进度回调。
  void Function(String stage, int done, int total)? onProgress;

  /// 1) 历史邮件 → 规则（增量）。
  ///
  /// [emails] 必须是已过滤（未消费）、已排序的邮件集合；
  /// [spaceAddresses] 用于在材料中标注「我方/客户」角色（小写地址集合）。
  /// 返回本次消费记录（含每封邮件参与生成的规则 ID）。
  Future<EmailLearningResult> generateFromEmails(
    List<EmailSummary> emails, {
    required List<String> folders,
    required Set<String> spaceAddresses,
  }) async {
    final newRulesTotal = <Rule>[];
    final consumedMap = <String, List<String>>{}; // messageId -> ruleIds

    // 按线程聚合同一批，线程内升序；跨线程也按最早时间升序。
    final batches = _buildAscendingBatches(emails);

    for (var i = 0; i < batches.length; i++) {
      final batch = batches[i];
      onProgress?.call('正在分析第 ${i + 1}/${batches.length} 批往来邮件',
          i + 1, batches.length);
      final dateRange = _dateRangeText(batch);
      var incomingCount = 0;
      for (final e in batch) {
        if (!spaceAddresses.contains(e.fromAddress.trim().toLowerCase())) {
          incomingCount++;
        }
      }
      AppLog.log('learn', '批次 ${i + 1}/${batches.length}：邮件 ${batch.length} 封'
          '（客户来信 $incomingCount、我方回复 ${batch.length - incomingCount}），'
          '日期 $dateRange');
      final batchText =
          batch.map((e) => e.toLearningText(spaceAddresses)).join('\n');
      final raw = await llm.chatJson([
        LlmMessage.user(prompts.emailRulesPrompt(batchText, dateRange)),
      ]);
      final extracted = parseRuleItems(raw);
      AppLog.log('learn', '批次 ${i + 1}/${batches.length}：提取 ${extracted.length} 条规则');
      if (extracted.isEmpty) continue;

      final messageIds = batch.map((e) => e.messageId).toList();
      final batchRules = <Rule>[];
      for (final item in extracted) {
        final rule = newRuleFromGeneration(
          type: RuleSourceType.emailHistory,
          generatedBy: llm.generatedBy,
          details: {
            'message_ids': messageIds,
            'subjects': batch.map((e) => e.subject).take(5).toList(),
            'folders': folders,
            'date_range': dateRange,
          },
          content: item.content,
          category: item.category,
        );
        batchRules.add(rule);
      }

      // 与现有规则库合并（冲突时新规则胜出）。
      onProgress?.call(
          '正在合并规则（第 ${i + 1}/${batches.length} 批）', i + 1, batches.length);
      final merged = await mergeBatch(batchRules);
      AppLog.log('learn', '批次 ${i + 1}/${batches.length}：合并后新增 '
          '${merged.added.length} 条、更新 ${merged.updatedRuleIds.length} 条');
      final touchedIds = [
        ...merged.added.map((r) => r.id),
        ...merged.updatedRuleIds,
      ];
      newRulesTotal.addAll(merged.added);
      for (final mid in messageIds) {
        consumedMap.putIfAbsent(mid, () => []).addAll(touchedIds);
      }
    }
    return EmailLearningResult(
      addedRules: newRulesTotal,
      updatedRuleIds: consumedMap.values.expand((l) => l).toSet().toList(),
      consumedMessageIds: consumedMap,
    );
  }

  /// 将一批新规则合并进规则库，返回合并结果。
  Future<MergeResult> mergeBatch(List<Rule> newRules) async {
    final existing = store.enabledRules;
    if (newRules.isEmpty) {
      return MergeResult(const [], const {}, const []);
    }

    // 现有规则太少时无需 LLM 合并，直接去重添加。
    if (existing.isEmpty) {
      await store.addAll(newRules);
      return MergeResult(newRules, const {}, const []);
    }

    final existingText = existing
        .map((r) => '${r.id} | ${r.category.toYamlName()} | ${r.content}')
        .join('\n');
    final newRulesText = newRules
        .map((r) => '- [${r.category.toYamlName()}] ${r.content}')
        .join('\n');

    final raw = await llm.chatJson([
      LlmMessage.user(
          prompts.mergeRulesPrompt(existingText, newRulesText)),
    ]);
    final list = raw is List ? raw : (raw is Map ? (raw['operations'] as List? ?? []) : []);
    final items = list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final added = <Rule>[];
    final updatedIds = <String>[];

    for (final item in items) {
      final op = readStr(item, ['op'])?.toLowerCase();
      final targetId = readStr(item, ['target_id', 'targetId', 'id']);
      final content = readStr(item, ['content']);
      final reason = readStr(item, ['reason']) ?? '';
      switch (op) {
        case 'add' when content != null:
          final category =
              RuleCategory.fromName(readStr(item, ['category']));
          final rule = newRuleFromGeneration(
            type: newRules.first.source.type,
            generatedBy: llm.generatedBy,
            details: {
              ...newRules.first.source.details,
              'merge_reason': reason,
            },
            content: content,
            category: category,
          );
          added.add(rule);
        case 'update'
            when targetId != null && content != null:
          await store.updateContent(
            targetId,
            content,
            reason: '合并更新：$reason',
          );
          updatedIds.add(targetId);
        case 'disable' when targetId != null:
          await store.setEnabled(targetId, false);
          updatedIds.add(targetId);
      }
    }
    if (added.isNotEmpty) await store.addAll(added);
    return MergeResult(added, const {}, updatedIds);
  }

  /// 2) 知识库 → 规则。
  Future<List<Rule>> generateFromKbDoc({
    required String docName,
    required String docHash,
    required String content,
  }) async {
    final chunks = _chunkText(content, 3000);
    final rules = <Rule>[];
    for (var i = 0; i < chunks.length; i++) {
      onProgress?.call(
          '正在从《$docName》提取规则（片段 ${i + 1}/${chunks.length}）',
          i + 1,
          chunks.length);
      final raw = await llm.chatJson([
        LlmMessage.user(prompts.kbRulesPrompt(docName, chunks[i])),
      ]);
      for (final item in parseRuleItems(raw)) {
        rules.add(newRuleFromGeneration(
          type: RuleSourceType.knowledgeBase,
          generatedBy: llm.generatedBy,
          details: {
            'doc': docName,
            'doc_hash': docHash,
            'chunk_index': i + 1,
            'chunk_total': chunks.length,
          },
          content: item.content,
          category: item.category,
        ));
      }
    }
    if (rules.isNotEmpty) await store.addAll(rules);
    return rules;
  }

  /// 3) 用户自定义 prompt → 规则（规范化拆分，返回待用户确认的规则草案）。
  Future<List<(RuleCategory, String)>> draftFromUserPrompt(
      String promptText) async {
    final raw = await llm.chatJson([
      LlmMessage.user(prompts.userPromptRulesPrompt(promptText)),
    ]);
    return parseRuleItems(raw)
        .map((e) => (e.category, e.content))
        .toList();
  }

  /// 直接把用户 prompt 原文落为一条规则（不经 LLM）。
  Future<Rule> addRawUserPromptRule(String promptText) => store.add(
        newRuleFromGeneration(
          type: RuleSourceType.userPrompt,
          generatedBy: '',
          details: {'prompt_text': promptText},
          content: promptText,
          category: RuleCategory.other,
        ),
      );

  // ------------------------------------------------------------------

  /// 按线程聚类后按时间升序分批（防旧覆盖新的第一步）。
  List<List<EmailSummary>> _buildAscendingBatches(List<EmailSummary> emails) {
    final sorted = [...emails]..sort((a, b) =>
        (a.parsedDate ?? DateTime(2000)).compareTo(b.parsedDate ?? DateTime(2000)));

    // 线程聚类：规范键相同的排在一起（客户来信与 我方回复 同线程同批），
    // 块内保持时间升序。
    final byThread = <String, List<EmailSummary>>{};
    for (final e in sorted) {
      byThread.putIfAbsent(canonicalThreadKey(e), () => []).add(e);
    }
    final threads = byThread.values.toList()
      ..sort((a, b) => (a.first.parsedDate ?? DateTime(2000))
          .compareTo(b.first.parsedDate ?? DateTime(2000)));

    final batches = <List<EmailSummary>>[];
    var current = <EmailSummary>[];
    var currentChars = 0;
    for (final thread in threads) {
      final threadChars =
          thread.map((e) => e.bodyText.length).fold<int>(0, (a, b) => a + b);
      if (current.isNotEmpty && currentChars + threadChars > _emailBatchChars) {
        batches.add(current);
        current = [];
        currentChars = 0;
      }
      current.addAll(thread);
      currentChars += threadChars;
    }
    if (current.isNotEmpty) batches.add(current);
    return batches;
  }

  String _dateRangeText(List<EmailSummary> batch) {
    final dates = batch
        .map((e) => e.parsedDate)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return '日期未知';
    dates.sort();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${fmt(dates.first)} ~ ${fmt(dates.last)}';
  }

  /// 解析模型返回的规则列表，接受三种形态：
  /// 1. 已解码的 List（[LlmClient.chatJson] 的正常返回）；
  /// 2. {"rules": [...]} 对象兜底；
  /// 3. 原始 JSON 字符串（测试 / 旧路径兼容）。
  ///
  /// 解析失败抛 FormatException（由调用方提示用户），不再静默吞掉；
  /// 此前对已解码对象误走 `toString()` 再解析的路径，曾导致所有提取结果为空。
  static List<RuleItem> parseRuleItems(dynamic raw) {
    try {
      return _parseDecodedRuleItems(raw);
    } on FormatException catch (e) {
      AppLog.log('learn', '规则解析失败：$e；模型输出片段：${_snippet(raw)}');
      rethrow;
    }
  }

  static List<RuleItem> _parseDecodedRuleItems(dynamic raw) {
    final result = <RuleItem>[];
    List<Map<String, dynamic>> items;
    if (raw is List) {
      items = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (raw is Map) {
      List? list;
      for (final v in raw.values) {
        if (v is List) {
          list = v;
          break;
        }
      }
      if (list == null) {
        throw const FormatException('模型输出对象中不含规则数组');
      }
      items = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (raw is String) {
      items = extractJsonList(raw);
    } else {
      throw FormatException('模型输出不是规则数组（${raw.runtimeType}）');
    }
    for (final item in items) {
      final content = readStr(item, ['content', 'rule', 'text']);
      if (content == null || content.length < 4) continue;
      final category = RuleCategory.fromName(readStr(item, ['category']));
      result.add(RuleItem(category, content));
    }
    return result;
  }

  static String _snippet(dynamic raw) {
    final s = raw.toString();
    return s.length > 200 ? '${s.substring(0, 200)}…' : s;
  }

  /// 按段落边界分块。
  List<String> _chunkText(String text, int maxChars) {
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    final chunks = <String>[];
    var buf = StringBuffer();
    for (final p in paragraphs) {
      if (buf.length + p.length > maxChars && buf.isNotEmpty) {
        chunks.add(buf.toString());
        buf = StringBuffer();
      }
      buf.writeln(p);
      buf.writeln();
      // 单段超长时硬切。
      if (buf.length > maxChars * 2) {
        final s = buf.toString();
        for (var i = 0; i < s.length; i += maxChars) {
          chunks.add(s.substring(i, i + maxChars > s.length ? s.length : i + maxChars));
        }
        buf = StringBuffer();
      }
    }
    if (buf.toString().trim().isNotEmpty) chunks.add(buf.toString());
    return chunks.where((c) => c.trim().isNotEmpty).toList();
  }
}

class RuleItem {
  const RuleItem(this.category, this.content);

  final RuleCategory category;
  final String content;
}

class MergeResult {
  const MergeResult(this.added, this.messageRuleIds, this.updatedRuleIds);

  final List<Rule> added;

  /// messageId → 规则 ID 列表（归因）。
  final Map<String, List<String>> messageRuleIds;
  final List<String> updatedRuleIds;
}

class EmailLearningResult {
  const EmailLearningResult({
    required this.addedRules,
    required this.updatedRuleIds,
    required this.consumedMessageIds,
  });

  final List<Rule> addedRules;
  final List<String> updatedRuleIds;

  /// messageId → 参与生成的规则 ID。
  final Map<String, List<String>> consumedMessageIds;
}
