/// 草稿状态。
enum DraftStatus {
  /// 已生成、待编辑/发送。
  editing,

  /// 未经修改直接发送。
  sentUnmodified,

  /// 修改后发送（触发规则反馈学习）。
  sentEdited,

  /// 已丢弃。
  discarded;

  String get label => switch (this) {
        DraftStatus.editing => '编辑中',
        DraftStatus.sentUnmodified => '已发送（未修改）',
        DraftStatus.sentEdited => '已发送（修改后）',
        DraftStatus.discarded => '已丢弃',
      };

  static DraftStatus fromName(String? name) => DraftStatus.values
      .firstWhere((e) => e.name == name, orElse: () => DraftStatus.editing);
}

/// 一次草稿修改反馈导致的规则变更。
class RuleUpdateRecord {
  const RuleUpdateRecord({
    required this.action,
    required this.summary,
    this.ruleId,
  });

  /// add / update / disable。
  final String action;
  final String summary;

  /// 涉及的规则 ID（add 时是新规则 ID）。
  final String? ruleId;

  Map<String, dynamic> toMap() => {
        'action': action,
        'summary': summary,
        'rule_id': ruleId,
      };

  static RuleUpdateRecord fromMap(Map<dynamic, dynamic> map) =>
      RuleUpdateRecord(
        action: map['action'] as String? ?? '',
        summary: map['summary'] as String? ?? '',
        ruleId: map['rule_id'] as String?,
      );
}

/// 草稿记录：从生成到发送的完整链路。
class DraftRecord {
  DraftRecord({
    required this.id,
    required this.emailMessageId,
    required this.subject,
    required this.toAddress,
    required this.originalDraft,
    required this.usedRuleIds,
    required this.createdAt,
    required this.status,
    this.threadContextDigest = '',
    this.finalSentText,
    this.wasModified = false,
    this.diffSummary,
    this.ruleUpdates = const [],
    this.sentAt,
    this.llmGeneratedBy = '',
    this.accountId = '',
    List<String>? extraCc,
  }) : extraCc = extraCc ?? [];

  final String id;

  /// 对应来信的 Message-ID。
  final String emailMessageId;
  final String subject;
  final String toAddress;

  /// LLM 生成的原始草稿（未编辑）。
  final String originalDraft;

  /// 生成时注入的规则 ID 列表（用于反馈统计与追溯）。
  final List<String> usedRuleIds;

  /// 线程上下文摘要（来信前的往来概要，便于复盘）。
  final String threadContextDigest;

  final String createdAt;
  DraftStatus status;

  /// 实际发送的文本。
  String? finalSentText;

  /// 是否被用户修改过（与原始草稿对比）。
  bool wasModified;

  /// 修改摘要（LLM 分析）。
  String? diffSummary;

  /// 反馈学习产生的规则变更。
  List<RuleUpdateRecord> ruleUpdates;

  DateTime? sentAt;

  /// 生成草稿的模型标识。
  final String llmGeneratedBy;

  /// 收信账号 ID（哪个账号收到这封来信，发信时优先用它回信）。
  final String accountId;

  /// 回信时需要抄送的地址（通常是转发场景的原始收件地址），发送前可编辑。
  List<String> extraCc;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email_message_id': emailMessageId,
        'subject': subject,
        'to_address': toAddress,
        'original_draft': originalDraft,
        'used_rule_ids': usedRuleIds,
        'thread_context_digest': threadContextDigest,
        'created_at': createdAt,
        'status': status.name,
        'final_sent_text': finalSentText,
        'was_modified': wasModified,
        'diff_summary': diffSummary,
        'rule_updates': ruleUpdates.map((e) => e.toMap()).toList(),
        'sent_at': sentAt?.toIso8601String(),
        'llm_generated_by': llmGeneratedBy,
        'account_id': accountId,
        'extra_cc': extraCc,
      };

  static DraftRecord fromMap(Map<dynamic, dynamic> map) => DraftRecord(
        id: map['id'] as String? ?? '',
        emailMessageId: map['email_message_id'] as String? ?? '',
        subject: map['subject'] as String? ?? '',
        toAddress: map['to_address'] as String? ?? '',
        originalDraft: map['original_draft'] as String? ?? '',
        usedRuleIds: (map['used_rule_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        threadContextDigest: map['thread_context_digest'] as String? ?? '',
        createdAt: map['created_at'] as String? ?? '',
        status: DraftStatus.fromName(map['status'] as String?),
        finalSentText: map['final_sent_text'] as String?,
        wasModified: map['was_modified'] as bool? ?? false,
        diffSummary: map['diff_summary'] as String?,
        ruleUpdates: (map['rule_updates'] as List? ?? [])
            .map((e) => RuleUpdateRecord.fromMap(e as Map))
            .toList(),
        sentAt: DateTime.tryParse(map['sent_at'] as String? ?? ''),
        llmGeneratedBy: map['llm_generated_by'] as String? ?? '',
        accountId: map['account_id'] as String? ?? '',
        extraCc: (map['extra_cc'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
