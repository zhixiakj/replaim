import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:replaim/models/email_summary.dart';
import 'package:replaim/services/stores.dart';

EmailSummary _mail({
  required String messageId,
  required String date,
  int? uid,
  String accountId = 'a1',
  String subject = '主题',
}) =>
    EmailSummary(
      messageId: messageId,
      subject: subject,
      fromAddress: 'peer@example.com',
      toAddresses: ['me@example.com'],
      date: date,
      folder: 'INBOX',
      bodyText: '正文 $messageId',
      snippet: '摘要 $messageId',
      inReplyTo: '<prev@example.com>',
      referencesIds: ['<root@example.com>', '<prev@example.com>'],
      accountId: accountId,
      originalRecipients: ['orig@example.com'],
      uid: uid,
    );

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('replaim_inbox_cache_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  group('EmailSummary 序列化', () {
    test('toMap/fromMap 全字段 round-trip', () {
      final m = _mail(
        messageId: '<m1@example.com>',
        date: '2026-10-07T10:00:00.000',
        uid: 42,
      );
      final back = EmailSummary.fromMap(m.toMap());
      expect(back.messageId, m.messageId);
      expect(back.subject, m.subject);
      expect(back.fromAddress, m.fromAddress);
      expect(back.toAddresses, m.toAddresses);
      expect(back.date, m.date);
      expect(back.folder, m.folder);
      expect(back.bodyText, m.bodyText);
      expect(back.snippet, m.snippet);
      expect(back.inReplyTo, m.inReplyTo);
      expect(back.referencesIds, m.referencesIds);
      expect(back.accountId, m.accountId);
      expect(back.originalRecipients, m.originalRecipients);
      expect(back.uid, m.uid);
    });

    test('可空字段缺失时容忍', () {
      final back = EmailSummary.fromMap(const {});
      expect(back.messageId, '');
      expect(back.inReplyTo, isNull);
      expect(back.referencesIds, isEmpty);
      expect(back.uid, isNull);
    });
  });

  group('InboxCacheStore', () {
    test('save → load round-trip（含同步状态）', () async {
      final store = InboxCacheStore(dir: Directory('${tmp.path}/inbox_cache'));
      final messages = [
        _mail(
            messageId: '<a@example.com>',
            date: '2026-10-07T10:00:00.000',
            uid: 100),
        _mail(
            messageId: '<b@example.com>',
            date: '2026-10-06T09:00:00.000',
            uid: 99),
      ];
      await store.save(
        'acc1',
        InboxCacheEntry(
          messages: messages,
          uidValidity: 12345,
          lastUid: 100,
          fetchedAt: DateTime(2026, 10, 7, 12),
        ),
      );
      final back = await store.load('acc1');
      expect(back, isNotNull);
      expect(back!.uidValidity, 12345);
      expect(back.lastUid, 100);
      expect(back.fetchedAt, DateTime(2026, 10, 7, 12));
      expect(back.messages.length, 2);
      expect(back.messages.first.uid, 100);
      expect(back.messages.first.bodyText, messages.first.bodyText);
    });

    test('缺失/损坏文件 load 返回 null', () async {
      final dir = Directory('${tmp.path}/inbox_cache');
      final store = InboxCacheStore(dir: dir);
      expect(await store.load('none'), isNull);
      await dir.create(recursive: true);
      File('${dir.path}/broken.yaml').writeAsStringSync('a: [unclosed');
      expect(await store.load('broken'), isNull);
    });

    test('loadAll 只合并有效账号并按时间倒序', () async {
      final store = InboxCacheStore(dir: Directory('${tmp.path}/inbox_cache'));
      await store.save(
          'a1',
          InboxCacheEntry(messages: [
            _mail(
                messageId: '<old@example.com>',
                date: '2026-10-05T08:00:00.000',
                uid: 10)
          ]));
      await store.save(
          'a2',
          InboxCacheEntry(messages: [
            _mail(
                messageId: '<new@example.com>',
                date: '2026-10-07T08:00:00.000',
                uid: 7)
          ]));
      await store.save(
          'removed',
          InboxCacheEntry(messages: [
            _mail(
                messageId: '<gone@example.com>',
                date: '2026-10-06T08:00:00.000',
                uid: 3)
          ]));
      final merged = await store.loadAll({'a1', 'a2'});
      expect(merged.length, 2);
      expect(merged.first.messageId, '<new@example.com>');
      expect(merged.last.messageId, '<old@example.com>');
    });

    test('prune 删除已移出空间的账号缓存', () async {
      final store = InboxCacheStore(dir: Directory('${tmp.path}/inbox_cache'));
      await store.save('a1', InboxCacheEntry(messages: []));
      await store.save('gone', InboxCacheEntry(messages: []));
      await store.prune({'a1'});
      expect(await store.load('a1'), isNotNull);
      expect(await store.load('gone'), isNull);
    });
  });

  group('mergeInboxMessages', () {
    test('新数据按 UID 覆盖缓存旧数据，倒序合并', () {
      final cached = [
        _mail(
            messageId: '<m1@x>',
            date: '2026-10-05T08:00:00.000',
            uid: 10,
            subject: '旧标题'),
      ];
      final fetched = [
        _mail(
            messageId: '<m1@x>',
            date: '2026-10-05T08:00:00.000',
            uid: 10,
            subject: '新标题'),
        _mail(
            messageId: '<m2@x>',
            date: '2026-10-07T08:00:00.000',
            uid: 11),
      ];
      final merged = mergeInboxMessages(cached, fetched);
      expect(merged.length, 2);
      expect(merged.first.messageId, '<m2@x>');
      expect(
          merged.last.subject, '新标题'); // fetched 覆盖 cached
    });

    test('无 UID 时退化为 Message-ID 去重', () {
      final cached = [
        _mail(messageId: '<same@x>', date: '2026-10-05T08:00:00.000'),
      ];
      final fetched = [
        _mail(messageId: '<same@x>', date: '2026-10-05T08:00:00.000'),
      ];
      expect(mergeInboxMessages(cached, fetched).length, 1);
    });

    test('超过 limit 截取最近 N 封', () {
      final cached = [
        for (var i = 0; i < 60; i++)
          _mail(
              messageId: '<m$i@x>',
              date: DateTime(2026, 10, 1, 0, i).toIso8601String(),
              uid: i),
      ];
      final merged = mergeInboxMessages(cached, const [], limit: 50);
      expect(merged.length, 50);
      expect(merged.first.uid, 59); // 最新的在前
    });

    test('同 UID 不同账号不去重', () {
      final a = _mail(
          messageId: '<x@x>', date: '2026-10-05T08:00:00.000',
          uid: 5, accountId: 'a1');
      final b = _mail(
          messageId: '<x@x>', date: '2026-10-05T08:00:00.000',
          uid: 5, accountId: 'a2');
      expect(mergeInboxMessages([a], [b]).length, 2);
    });
  });
}
