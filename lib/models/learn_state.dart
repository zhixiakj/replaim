/// 历史邮件学习状态：记录哪些邮件已被用于生成规则。
///
/// 目的：
/// 1. 避免同一封邮件被重复消费（浪费 token、规则重复）；
/// 2. 增量学习只处理新邮件；
/// 3. 配合「按时间升序处理 + 冲突时新规则优先」的策略，
///    避免旧邮件的内容覆盖新邮件已经更新过的规则。
class ConsumedEmail {
  const ConsumedEmail({
    required this.messageId,
    required this.date,
    required this.subject,
    required this.from,
    required this.folder,
    required this.learnedAt,
    required this.generatedRuleIds,
  });

  /// 邮件 Message-ID 头（含尖括号），全局唯一。
  final String messageId;

  /// 邮件日期（ISO 字符串）。
  final String date;
  final String subject;
  final String from;
  final String folder;

  /// 被学习处理的时间。
  final String learnedAt;

  /// 该邮件参与生成的规则 ID。
  final List<String> generatedRuleIds;

  Map<String, dynamic> toMap() => {
        'message_id': messageId,
        'date': date,
        'subject': subject,
        'from': from,
        'folder': folder,
        'learned_at': learnedAt,
        'generated_rule_ids': generatedRuleIds,
      };

  static ConsumedEmail fromMap(Map<dynamic, dynamic> map) => ConsumedEmail(
        messageId: map['message_id'] as String? ?? '',
        date: map['date'] as String? ?? '',
        subject: map['subject'] as String? ?? '',
        from: map['from'] as String? ?? '',
        folder: map['folder'] as String? ?? '',
        learnedAt: map['learned_at'] as String? ?? '',
        generatedRuleIds: (map['generated_rule_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class LearnState {
  LearnState({this.consumed = const [], this.lastRunAt});

  final List<ConsumedEmail> consumed;

  /// 上次学习完成时间。
  final DateTime? lastRunAt;

  bool hasConsumed(String messageId) =>
      consumed.any((e) => e.messageId == messageId);

  LearnState withAdded(List<ConsumedEmail> newItems, DateTime runAt) =>
      LearnState(
        consumed: [...consumed, ...newItems],
        lastRunAt: runAt,
      );

  Map<String, dynamic> toMap() => {
        'consumed': consumed.map((e) => e.toMap()).toList(),
        'last_run_at': lastRunAt?.toIso8601String(),
      };

  static LearnState fromMap(Map<dynamic, dynamic> map) => LearnState(
        consumed: (map['consumed'] as List? ?? [])
            .map((e) => ConsumedEmail.fromMap(e as Map))
            .toList(),
        lastRunAt: DateTime.tryParse(map['last_run_at'] as String? ?? ''),
      );

  static LearnState empty() => LearnState();
}
