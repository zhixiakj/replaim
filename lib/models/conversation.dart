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

  bool isFromMe(EmailSummary m) =>
      meAddresses.contains(m.fromAddress.toLowerCase().trim());
}

/// 按参与人集合把邮件汇总成会话列表（按最后活动时间倒序）。
///
/// 每封邮件的参与人 = 发件人（若非本空间地址）∪ 全部非本空间的 To 收件人：
/// - 「张三→我」与「我→张三」的参与人集合相同，进同一会话；
/// - 群发/抄送场景按收件人集合归为一个群会话（Cc 不入库，不参与归组）；
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
  final set = <String>{};
  final from = m.fromAddress.toLowerCase().trim();
  if (from.isNotEmpty && !me.contains(from)) set.add(from);
  for (final raw in m.toAddresses) {
    final addr = raw.toLowerCase().trim();
    if (addr.isNotEmpty && !me.contains(addr)) set.add(addr);
  }
  final list = set.toList()..sort();
  return list;
}
