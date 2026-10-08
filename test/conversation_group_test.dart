import 'package:flutter_test/flutter_test.dart';
import 'package:replaim/models/conversation.dart';
import 'package:replaim/models/email_summary.dart';

EmailSummary _mail(
  String messageId,
  String from,
  List<String> to,
  String date, {
  String subject = '主题',
  String folder = 'INBOX',
  List<String> originalRecipients = const [],
}) =>
    EmailSummary(
      messageId: messageId,
      subject: subject,
      fromAddress: from,
      toAddresses: to,
      date: date,
      folder: folder,
      bodyText: '正文 $messageId',
      snippet: '摘要 $messageId',
      accountId: 'a1',
      originalRecipients: originalRecipients,
    );

void main() {
  const me = {'me@example.com'};

  group('groupConversations', () {
    test('双向往来合并为同一会话，会话内按时间升序', () {
      final list = [
        _mail('<1@x>', 'peer@example.com', ['me@example.com'],
            '2026-10-01T10:00:00.000'),
        _mail('<2@x>', 'me@example.com', ['peer@example.com'],
            '2026-10-02T10:00:00.000',
            folder: 'Sent'),
        _mail('<3@x>', 'peer@example.com', ['me@example.com'],
            '2026-10-03T10:00:00.000'),
      ];
      final convs = groupConversations(list, me);
      expect(convs.length, 1);
      expect(convs.first.participants, ['peer@example.com']);
      expect(convs.first.messages.length, 3);
      expect(convs.first.messages.first.messageId, '<1@x>');
      expect(convs.first.messages.last.messageId, '<3@x>');
    });

    test('不同参与人是不同会话，列表按最后活动时间倒序', () {
      final list = [
        _mail('<a1@x>', 'a@x.com', ['me@example.com'],
            '2026-10-01T10:00:00.000'),
        _mail('<b1@x>', 'b@x.com', ['me@example.com'],
            '2026-10-05T10:00:00.000'),
        _mail('<a2@x>', 'a@x.com', ['me@example.com'],
            '2026-10-03T10:00:00.000'),
      ];
      final convs = groupConversations(list, me);
      expect(convs.length, 2);
      expect(convs.first.participants, ['b@x.com']); // 最新活动 10-05
      expect(convs.last.messages.length, 2);
    });

    test('多收件人按参与人集合归为群会话', () {
      final list = [
        _mail('<g1@x>', 'me@example.com', ['a@x.com', 'b@x.com'],
            '2026-10-01T10:00:00.000',
            folder: 'Sent'),
        _mail('<g2@x>', 'a@x.com', ['me@example.com', 'b@x.com'],
            '2026-10-02T10:00:00.000'),
        _mail('<solo@x>', 'a@x.com', ['me@example.com'],
            '2026-10-03T10:00:00.000'),
      ];
      final convs = groupConversations(list, me);
      expect(convs.length, 2);
      final group = convs.firstWhere((c) => c.messages.length == 2);
      expect(group.participants, ['a@x.com', 'b@x.com']);
    });

    test('参与人地址大小写与首尾空格归一', () {
      final list = [
        _mail('<1@x>', 'Peer@Example.com ', ['ME@example.com'],
            '2026-10-01T10:00:00.000'),
        _mail('<2@x>', 'me@example.com', [' peer@example.com '],
            '2026-10-02T10:00:00.000',
            folder: 'Sent'),
      ];
      final convs = groupConversations(list, me);
      expect(convs.length, 1);
      expect(convs.first.participants, ['peer@example.com']);
    });

    test('lastFromMe / latestIncoming / hasForwarded', () {
      final list = [
        _mail('<1@x>', 'peer@example.com', ['me@example.com'],
            '2026-10-01T10:00:00.000',
            originalRecipients: ['orig@x.com']),
        _mail('<2@x>', 'me@example.com', ['peer@example.com'],
            '2026-10-02T10:00:00.000',
            folder: 'Sent'),
      ];
      final conv = groupConversations(list, me).first;
      expect(conv.lastFromMe, isTrue);
      expect(conv.latestIncoming!.messageId, '<1@x>');
      expect(conv.hasForwarded, isTrue);
    });

    test('发给自己的邮件归为空参与人会话，不抛异常', () {
      final list = [
        _mail('<self@x>', 'me@example.com', ['me@example.com'],
            '2026-10-01T10:00:00.000',
            folder: 'Sent'),
      ];
      final convs = groupConversations(list, me);
      expect(convs.length, 1);
      expect(convs.first.participants, isEmpty);
      expect(convs.first.lastFromMe, isTrue);
      expect(convs.first.latestIncoming, isNull);
    });

    test('本空间多个账号与同一对方的往来也合并（跨账号）', () {
      final list = [
        _mail('<1@x>', 'peer@example.com', ['me@example.com'],
            '2026-10-01T10:00:00.000'),
        _mail('<2@x>', 'me2@example.com', ['peer@example.com'],
            '2026-10-02T10:00:00.000',
            folder: 'Sent'),
      ];
      final convs =
          groupConversations(list, {'me@example.com', 'me2@example.com'});
      expect(convs.length, 1);
      expect(convs.first.messages.length, 2);
    });
  });
}
