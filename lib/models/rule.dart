import '../services/id_gen.dart';

/// 规则来源类型。
enum RuleSourceType {
  emailHistory,
  knowledgeBase,
  userPrompt,
  draftFeedback,
  manual;

  String get label => switch (this) {
        RuleSourceType.emailHistory => '历史邮件',
        RuleSourceType.knowledgeBase => '知识库',
        RuleSourceType.userPrompt => '自定义 Prompt',
        RuleSourceType.draftFeedback => '草稿修改反馈',
        RuleSourceType.manual => '手动添加',
      };

  static RuleSourceType fromName(String? name) => RuleSourceType.values
      .firstWhere((e) => e.name == name, orElse: () => RuleSourceType.manual);

  String toYamlName() => switch (this) {
        RuleSourceType.emailHistory => 'email_history',
        RuleSourceType.knowledgeBase => 'knowledge_base',
        RuleSourceType.userPrompt => 'user_prompt',
        RuleSourceType.draftFeedback => 'draft_feedback',
        RuleSourceType.manual => 'manual',
      };

  static RuleSourceType fromYamlName(String? name) {
    switch (name) {
      case 'email_history':
        return RuleSourceType.emailHistory;
      case 'knowledge_base':
        return RuleSourceType.knowledgeBase;
      case 'user_prompt':
        return RuleSourceType.userPrompt;
      case 'draft_feedback':
        return RuleSourceType.draftFeedback;
      default:
        return RuleSourceType.manual;
    }
  }
}

/// 规则类目。
enum RuleCategory {
  tone,
  policy,
  format,
  product,
  compliance,
  other;

  String get label => switch (this) {
        RuleCategory.tone => '语气风格',
        RuleCategory.policy => '售后政策',
        RuleCategory.format => '格式结构',
        RuleCategory.product => '商品信息',
        RuleCategory.compliance => '平台合规',
        RuleCategory.other => '其他',
      };

  static RuleCategory fromName(String? name) => RuleCategory.values
      .firstWhere((e) => e.name == name, orElse: () => RuleCategory.other);

  String toYamlName() => name;

  static RuleCategory fromYamlName(String? name) =>
      RuleCategory.values.firstWhere((e) => e.name == name,
          orElse: () => RuleCategory.other);
}

/// 规则使用统计。
class RuleStats {
  const RuleStats({
    this.usedCount = 0,
    this.keptUnchangedCount = 0,
    this.editedCount = 0,
  });

  /// 被用于生成草稿的次数。
  final int usedCount;

  /// 草稿未被修改直接发送的次数（规则有效信号）。
  final int keptUnchangedCount;

  /// 草稿被修改的次数（规则可能需要优化的信号）。
  final int editedCount;

  Map<String, dynamic> toMap() => {
        'used_count': usedCount,
        'kept_unchanged_count': keptUnchangedCount,
        'edited_count': editedCount,
      };

  static RuleStats fromMap(Map<dynamic, dynamic> map) => RuleStats(
        usedCount: map['used_count'] as int? ?? 0,
        keptUnchangedCount: map['kept_unchanged_count'] as int? ?? 0,
        editedCount: map['edited_count'] as int? ?? 0,
      );

  RuleStats copyWith({int? usedCount, int? keptUnchangedCount, int? editedCount}) =>
      RuleStats(
        usedCount: usedCount ?? this.usedCount,
        keptUnchangedCount: keptUnchangedCount ?? this.keptUnchangedCount,
        editedCount: editedCount ?? this.editedCount,
      );
}

/// 规则版本历史条目。
class RuleHistoryEntry {
  const RuleHistoryEntry({
    required this.version,
    required this.content,
    required this.updatedAt,
    required this.reason,
  });

  final int version;

  /// 该版本时的规则内容。
  final String content;
  final DateTime updatedAt;

  /// 变更原因（例如"来自草稿修改反馈：用户总是删除道歉语句"）。
  final String reason;

  Map<String, dynamic> toMap() => {
        'version': version,
        'content': content,
        'updated_at': updatedAt.toIso8601String(),
        'reason': reason,
      };

  static RuleHistoryEntry fromMap(Map<dynamic, dynamic> map) =>
      RuleHistoryEntry(
        version: map['version'] as int? ?? 1,
        content: map['content'] as String? ?? '',
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
            DateTime.now(),
        reason: map['reason'] as String? ?? '',
      );
}

/// 规则来源（provenance）：这条规则从哪来、怎么生成的。
class RuleSource {
  const RuleSource({
    required this.type,
    required this.createdAt,
    this.generatedBy = '',
    this.details = const {},
  });

  final RuleSourceType type;
  final DateTime createdAt;

  /// 生成该规则的模型与端点，例如 "deepseek-chat @ https://api.deepseek.com/v1"。
  /// 手动添加的规则为空。
  final String generatedBy;

  /// 按类型而异的来源明细，键值见各生成器：
  /// - email_history: message_ids / subjects / date_range
  /// - knowledge_base: doc / doc_hash / chunk_index
  /// - user_prompt: prompt_text
  /// - draft_feedback: draft_id / change_summary
  /// - manual: {}
  final Map<String, dynamic> details;

  Map<String, dynamic> toMap() => {
        'type': type.toYamlName(),
        'created_at': createdAt.toIso8601String(),
        'generated_by': generatedBy,
        'details': details,
      };

  static RuleSource fromMap(Map<dynamic, dynamic> map) => RuleSource(
        type: RuleSourceType.fromYamlName(map['type'] as String?),
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
        generatedBy: map['generated_by'] as String? ?? '',
        details: Map<String, dynamic>.from(map['details'] as Map? ?? {}),
      );
}

/// 一条回复规则——本应用的核心资产。
///
/// 草稿生成只依据规则（不直接引用知识库原文或历史邮件原文），
/// 因此规则的内容与来源必须完整可追溯。
class Rule {
  Rule({
    String? id,
    required this.content,
    required this.source,
    this.category = RuleCategory.other,
    this.enabled = true,
    this.version = 1,
    List<RuleHistoryEntry>? history,
    this.supersededBy,
    RuleStats? stats,
  })  : id = id ?? newRuleId(),
        history = history ?? [],
        stats = stats ?? const RuleStats();

  final String id;
  bool enabled;
  RuleCategory category;

  /// 规则正文（单段文字，不含换行，便于 YAML 存储与 prompt 注入）。
  String content;

  /// 当前版本的来源。
  RuleSource source;

  int version;

  /// 历史版本（不含当前版本）。
  List<RuleHistoryEntry> history;

  /// 被哪条规则取代（冲突时旧规则停用保留，不物理删除）。
  String? supersededBy;

  RuleStats stats;

  Map<String, dynamic> toMap() => {
        'id': id,
        'enabled': enabled,
        'category': category.toYamlName(),
        'content': content,
        'source': source.toMap(),
        'version': version,
        'history': history.map((e) => e.toMap()).toList(),
        'superseded_by': supersededBy,
        'stats': stats.toMap(),
      };

  static Rule fromMap(Map<dynamic, dynamic> map) => Rule(
        id: map['id'] as String?,
        content: map['content'] as String? ?? '',
        category: RuleCategory.fromYamlName(map['category'] as String?),
        enabled: map['enabled'] as bool? ?? true,
        source: RuleSource.fromMap(map['source'] as Map? ?? {}),
        version: map['version'] as int? ?? 1,
        history: (map['history'] as List? ?? [])
            .map((e) => RuleHistoryEntry.fromMap(e as Map))
            .toList(),
        supersededBy: map['superseded_by'] as String?,
        stats: RuleStats.fromMap(map['stats'] as Map? ?? {}),
      );
}
