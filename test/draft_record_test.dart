import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:replaim/models/draft_record.dart';
import 'package:replaim/models/email_summary.dart';
import 'package:replaim/services/draft_generator.dart';
import 'package:replaim/services/yaml_io.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('replaim_draft_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  DraftRecord buildRecord({
    DraftStatus status = DraftStatus.editing,
    String? currentText,
    List<DraftChatMessage>? chatHistory,
    String emailMessageId = '<incoming-1>',
    String? finalSentText,
    DateTime? sentAt,
  }) =>
      DraftRecord(
        id: 'draft_abc',
        emailMessageId: emailMessageId,
        subject: 'Where is my order',
        toAddress: 'buyer@example.com',
        originalDraft: 'Thanks for reaching out.',
        usedRuleIds: const ['r1'],
        createdAt: DateTime(2026, 10, 1).toIso8601String(),
        status: status,
        currentText: currentText,
        chatHistory: chatHistory,
        finalSentText: finalSentText,
        sentAt: sentAt,
        llmGeneratedBy: 'test-model @ http://localhost',
        accountId: 'acc1',
        extraCc: const ['orig@example.com'],
      );

  group('DraftRecord 序列化', () {
    test('currentText / chatHistory / sentManually roundtrip', () async {
      final record = buildRecord(
        status: DraftStatus.sentManually,
        currentText: 'Thanks, we will check it.',
        finalSentText: 'Thanks, we will check it.',
        sentAt: DateTime(2026, 10, 2),
        chatHistory: [
          DraftChatMessage(
            role: 'user',
            text: '语气更诚恳一点',
            at: DateTime(2026, 10, 2).toIso8601String(),
          ),
          DraftChatMessage(
            role: 'assistant',
            text: '已调整语气',
            body: 'Thanks, we will check it.',
            at: DateTime(2026, 10, 2).toIso8601String(),
          ),
        ],
      );
      final file = File('${tmp.path}/draft_abc.yaml');
      await writeYamlFile(file, record.toMap());
      final back = DraftRecord.fromMap(readYamlMap(file)!);

      expect(back.status, DraftStatus.sentManually);
      expect(back.currentText, 'Thanks, we will check it.');
      expect(back.finalSentText, 'Thanks, we will check it.');
      expect(back.chatHistory.length, 2);
      expect(back.chatHistory[0].isUser, isTrue);
      expect(back.chatHistory[0].text, '语气更诚恳一点');
      expect(back.chatHistory[1].body, 'Thanks, we will check it.');
      expect(back.effectiveText, 'Thanks, we will check it.');
    });

    test('旧 YAML（无新字段）容错', () {
      final legacy = <String, dynamic>{
        'id': 'draft_old',
        'email_message_id': '<incoming-1>',
        'subject': 's',
        'to_address': 'a@b.c',
        'original_draft': 'body',
        'used_rule_ids': ['r1'],
        'thread_context_digest': '',
        'created_at': '2026-09-01T00:00:00.000',
        'status': 'sentEdited',
        'final_sent_text': 'sent body',
        'was_modified': true,
        'rule_updates': [],
        'llm_generated_by': 'm',
        'account_id': 'acc1',
        'extra_cc': [],
      };
      final back = DraftRecord.fromMap(legacy);
      expect(back.currentText, isNull);
      expect(back.chatHistory, isEmpty);
      // 未记录编辑文本时回落原始草稿。
      expect(back.effectiveText, 'body');
    });

    test('currentText 为空白时 effectiveText 回落 originalDraft', () {
      final record = buildRecord(currentText: '   \n ');
      expect(record.effectiveText, 'Thanks for reaching out.');
    });

    test('未知状态名回落 editing', () {
      expect(DraftStatus.fromName('sentManually'), DraftStatus.sentManually);
      expect(DraftStatus.fromName('unknown-one'), DraftStatus.editing);
    });
  });

  group('sentDraftsAsThreadPeers', () {
    final incoming = EmailSummary(
      messageId: '<incoming-1>',
      subject: 'Where is my order',
      fromAddress: 'buyer@example.com',
      toAddresses: const ['support@shop.com'],
      date: '2026-10-01T10:00:00.000Z',
      folder: 'INBOX',
      bodyText: 'question',
    );

    test('已发送（含手工标注）注入，未发送 / 已丢弃 / 无关会话不注入', () {
      final drafts = [
        buildRecord(status: DraftStatus.editing),
        buildRecord(status: DraftStatus.discarded),
        buildRecord(
            status: DraftStatus.sentUnmodified,
            finalSentText: 'answer A',
            emailMessageId: '<other-thread>'),
        buildRecord(
            status: DraftStatus.sentUnmodified,
            finalSentText: 'answer B',
            sentAt: DateTime(2026, 10, 1, 12)),
        buildRecord(
            status: DraftStatus.sentManually,
            finalSentText: 'answer C',
            sentAt: DateTime(2026, 10, 1, 13)),
      ];
      final peers = sentDraftsAsThreadPeers(
        drafts: drafts,
        conversationMessageIds: {'<incoming-1>'},
        conversationMessages: [incoming],
        resolveSender: (_) => 'support@shop.com',
      );
      expect(peers.map((e) => e.bodyText), ['answer B', 'answer C']);
      for (final p in peers) {
        expect(p.messageId.startsWith('draft:'), isTrue);
        expect(p.folder, 'Sent');
        expect(p.inReplyTo, '<incoming-1>');
        expect(p.fromAddress, 'support@shop.com');
      }
    });

    test('正文已出现在会话我方邮件里（Sent 已同步）则跳过', () {
      final sentMail = EmailSummary(
        messageId: '<sent-real>',
        subject: 'Re: Where is my order',
        fromAddress: 'support@shop.com',
        toAddresses: const ['buyer@example.com'],
        date: '2026-10-01T12:00:00.000Z',
        folder: 'Sent',
        bodyText: 'answer B',
      );
      final drafts = [
        buildRecord(
            status: DraftStatus.sentUnmodified,
            finalSentText: 'answer B',
            sentAt: DateTime(2026, 10, 1, 12)),
      ];
      final peers = sentDraftsAsThreadPeers(
        drafts: drafts,
        conversationMessageIds: {'<incoming-1>', '<sent-real>'},
        conversationMessages: [incoming, sentMail],
        resolveSender: (_) => 'support@shop.com',
      );
      expect(peers, isEmpty);
    });

    test('真实邮件正文未回填时按引用头 + 主题识别已同步', () {
      // 列表阶段刚同步的 Sent 邮件 bodyText 为空，只有 snippet。
      final sentMail = EmailSummary(
        messageId: '<sent-real>',
        subject: 'Re: Where is my order',
        fromAddress: 'support@shop.com',
        toAddresses: const ['buyer@example.com'],
        date: '2026-10-01T12:00:00.000Z',
        folder: 'Sent',
        bodyText: '',
        snippet: 'answer…',
        inReplyTo: '<incoming-1>',
      );
      final drafts = [
        buildRecord(
            status: DraftStatus.sentUnmodified,
            finalSentText: 'answer B',
            sentAt: DateTime(2026, 10, 1, 12)),
      ];
      final peers = sentDraftsAsThreadPeers(
        drafts: drafts,
        conversationMessageIds: {'<incoming-1>', '<sent-real>'},
        conversationMessages: [incoming, sentMail],
        resolveSender: (_) => 'support@shop.com',
      );
      expect(peers, isEmpty);
    });

    test('多份内容相同的草稿只注入一份', () {
      final drafts = [
        buildRecord(
            status: DraftStatus.sentManually,
            finalSentText: 'same answer',
            sentAt: DateTime(2026, 10, 1, 12)),
        buildRecord(
            status: DraftStatus.sentManually,
            finalSentText: 'same answer\n',
            sentAt: DateTime(2026, 10, 1, 13)),
      ];
      final peers = sentDraftsAsThreadPeers(
        drafts: drafts,
        conversationMessageIds: {'<incoming-1>'},
        conversationMessages: [incoming],
        resolveSender: (_) => 'support@shop.com',
      );
      expect(peers.length, 1);
    });
  });

  group('draftAsSentEmail', () {
    test('finalSentText 为空返回 null', () {
      final d = buildRecord(status: DraftStatus.sentManually);
      expect(draftAsSentEmail(d, 'support@shop.com'), isNull);
    });
  });
}
