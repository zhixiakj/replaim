import 'email_summary.dart';

/// 聊天式会话：同一组对方参与人（不含本空间账号地址）的全部往来邮件。
/// 「对方→我」与「我→对方」合并进同一会话，方向由 [isFromMe] 区分。
class Conversation {
  const Conversation({
    required this.key,
    required this.participants,
    required this.messages,
    required this.meAddresses,
  });

  /// 参与人集合的规范键：排序后的小写地址以「|」连接。
  final String key;

  /// 对方参与人地址（小写、排序）。发给自己（无外部参与人）的会话为空表。
  final List<String> participants;

  /// 会话内邮件，按时间升序。
  final List<EmailSummary> messages;

  /// 本空间全部账号地址（小写），判定「我方发出」用。
  final Set<String> meAddresses;

  EmailSummary get lastMessage => messages.last;

  bool get lastFromMe => isFromMe(messages.last);

  /// 会话中是否存在转发来件（列表小图标提示用）。
  bool get hasForwarded =>
      messages.any((m) => m.originalRecipients.isNotEmpty);

  /// 最新一封对方来件（打开会话时默认选中，供生成草稿）。
  EmailSummary? get latestIncoming {
    for (final m in messages.reversed) {
      if (!isFromMe(m)) return m;
    }
    return null;
  }

  /// 是否已回复（列表「已回」标记用）：最新一封对方来件之后已有我方发出
  /// （来件不是最后一封）。纯外发（从未有来件）与待回复均为 false，不标。
  bool get replied => latestIncoming != null && lastFromMe;

  bool isFromMe(EmailSummary m) =>
      meAddresses.contains(m.fromAddress.toLowerCase().trim());
}

/// 按参与人集合把邮件汇总成会话列表（按最后活动时间倒序）。
///
/// 方向不对称归组（对客服转发场景至关重要）：
/// - **来信**（发件人非本空间账号）只按发件人归组。来信 To/Cc 中的非空间
///   地址必然是 detectForwardedRecipients 判出的「原始收件」—— 即
///   support@xxx 这类转发别名（我方业务地址）或客户侧抄送，若计入参与人，
///   来信集合是 {客户, support@}，而回信（To=客户）集合是 {客户}，
///   同一客户的往来会被裂成两个会话；
/// - **去信**（发件人是本空间账号）按全部非空间 To 收件人归组（群发语义）。
/// - 参与人地址做小写与去空格归一。
List<Conversation> groupConversations(
    List<EmailSummary> messages, Set<String> meAddresses) {
  final me = meAddresses.map((a) => a.toLowerCase().trim()).toSet();
  final messagesByKey = <String, List<EmailSummary>>{};
  final participantsByKey = <String, List<String>>{};
  for (final m in messages) {
    final participants = _participantsOf(m, me);
    final key = participants.join('|');
    messagesByKey.putIfAbsent(key, () => []).add(m);
    participantsByKey[key] = participants;
  }
  final conversations = <Conversation>[];
  messagesByKey.forEach((key, list) {
    list.sort((a, b) => (a.parsedDate ?? DateTime(2000))
        .compareTo(b.parsedDate ?? DateTime(2000)));
    conversations.add(Conversation(
      key: key,
      participants: participantsByKey[key]!,
      messages: List.unmodifiable(list),
      meAddresses: me,
    ));
  });
  conversations.sort((a, b) => (b.lastMessage.parsedDate ?? DateTime(2000))
      .compareTo(a.lastMessage.parsedDate ?? DateTime(2000)));
  return conversations;
}

List<String> _participantsOf(EmailSummary m, Set<String> me) {
  final from = m.fromAddress.toLowerCase().trim();
  final fromMe = from.isNotEmpty && me.contains(from);
  if (!fromMe) return from.isEmpty ? <String>[] : [from];
  final set = <String>{};
  for (final raw in m.toAddresses) {
    final addr = raw.toLowerCase().trim();
    if (addr.isNotEmpty && !me.contains(addr)) set.add(addr);
  }
  return set.toList()..sort();
}
