import 'dart:io';

import '../models/rule.dart';
import 'id_gen.dart';
import 'paths.dart';
import 'yaml_io.dart';

/// 规则库存储：rules.yaml 的加载与全部变更操作。
///
/// 所有变更都走单一入口 [_save]，保证文件与内存一致；
/// 规则更新时旧内容进 history，冲突替代走 supersede（不物理删除）。
class RuleStore {
  RuleStore([File? file]) : _file = file ?? File(AppPaths.instance.rulesFile);

  final File _file;
  List<Rule> _rules = [];

  List<Rule> get rules => List.unmodifiable(_rules);
  List<Rule> get enabledRules => _rules.where((r) => r.enabled).toList();

  Future<void> load() async {
    final list = readYamlList(_file);
    _rules = list.map(Rule.fromMap).toList();
  }

  Future<void> _save() => writeYamlFile(_file, _rules.map((r) => r.toMap()).toList());

  Rule? findById(String id) {
    for (final r in _rules) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// 新增规则（幂等保存由调用方批量后调用 [persist] 也行，这里直接保存）。
  Future<Rule> add(Rule rule) async {
    _rules.add(rule);
    await _save();
    return rule;
  }

  Future<void> addAll(List<Rule> newRules) async {
    _rules.addAll(newRules);
    await _save();
  }

  /// 更新规则内容：版本 +1，旧内容与原因进 history。
  Future<void> updateContent(
    String id,
    String newContent, {
    String reason = '',
    RuleCategory? category,
    RuleSource? newSource,
  }) async {
    final rule = findById(id);
    if (rule == null) return;
    rule.history.add(RuleHistoryEntry(
      version: rule.version,
      content: rule.content,
      updatedAt: DateTime.now(),
      reason: reason,
    ));
    rule.content = newContent;
    if (category != null) rule.category = category;
    if (newSource != null) rule.source = newSource;
    rule.version++;
    await _save();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final rule = findById(id);
    if (rule == null) return;
    rule.enabled = enabled;
    await _save();
  }

  /// 冲突替代：旧规则停用保留，指向新规则。
  Future<void> supersede(String oldId, String newId) async {
    final rule = findById(oldId);
    if (rule == null) return;
    rule.enabled = false;
    rule.supersededBy = newId;
    await _save();
  }

  Future<void> delete(String id) async {
    _rules.removeWhere((r) => r.id == id);
    await _save();
  }

  /// 删除某来源文档的全部派生规则（知识库文档变更后重新生成前调用）。
  Future<void> deleteByKbDoc(String docName) async {
    _rules.removeWhere((r) =>
        r.source.type == RuleSourceType.knowledgeBase &&
        r.source.details['doc'] == docName);
    await _save();
  }

  Future<void> markStats(
    List<String> ruleIds, {
    bool used = false,
    bool keptUnchanged = false,
    bool edited = false,
  }) async {
    var changed = false;
    for (final id in ruleIds) {
      final rule = findById(id);
      if (rule == null) continue;
      rule.stats = rule.stats.copyWith(
        usedCount: used ? rule.stats.usedCount + 1 : null,
        keptUnchangedCount: keptUnchanged ? rule.stats.keptUnchangedCount + 1 : null,
        editedCount: edited ? rule.stats.editedCount + 1 : null,
      );
      changed = true;
    }
    if (changed) await _save();
  }

  /// 手动新建一条规则。
  Future<Rule> addManualRule(String content, RuleCategory category) => add(Rule(
        content: content,
        category: category,
        source: RuleSource(
          type: RuleSourceType.manual,
          createdAt: DateTime.now(),
        ),
      ));

  /// 合并操作落地后重新持久化（生成器内部改内存后调用）。
  Future<void> persist() => _save();
}

/// 构造带来源的新规则（生成器用）。
Rule newRuleFromGeneration({
  required RuleSourceType type,
  required String generatedBy,
  required Map<String, dynamic> details,
  required String content,
  required RuleCategory category,
}) =>
    Rule(
      id: newRuleId(),
      content: content,
      category: category,
      source: RuleSource(
        type: type,
        createdAt: DateTime.now(),
        generatedBy: generatedBy,
        details: details,
      ),
    );
