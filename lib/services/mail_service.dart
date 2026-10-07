import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:enough_mail/enough_mail.dart' show SocketType;

import '../models/email_summary.dart';
import '../models/mail_space.dart';

/// 邮件服务：IMAP 收件 + SMTP 发件（enough_mail 高层 API）。
///
/// 桌面端长期运行，每次操作独立连接、用完即断，避免 IMAP 空闲断连问题。
/// 每个实例对应一个邮箱账号，由调用方按空间账号临时构造。
class MailService {
  MailService(this.config, this.password);

  final MailAccountConfig config;
  final String? password;

  bool get isReceiveReady =>
      config.isReceiveConfigured && (password?.isNotEmpty ?? false);

  bool get isSendReady =>
      config.isSendConfigured && (password?.isNotEmpty ?? false);

  mail.MailAccount _buildAccount() => mail.MailAccount.fromManualSettings(
        name: config.displayName.isEmpty ? config.email : config.displayName,
        email: config.email,
        userName: config.email,
        incomingHost: config.imapHost,
        incomingPort: config.imapPort,
        incomingSocketType: config.imapSecure ? SocketType.ssl : SocketType.plain,
        // 纯收信账号 SMTP 可留空；enough_mail 要求非空，占位即可
        // （SMTP 懒连接，发信前另有 isSendReady 校验拦截）。
        outgoingHost:
            config.smtpHost.isEmpty ? 'smtp.unset.invalid' : config.smtpHost,
        outgoingPort: config.smtpPort,
        outgoingSocketType: _smtpSocketType(),
        password: password ?? '',
      );

  SocketType _smtpSocketType() {
    if (!config.smtpSecure) return SocketType.plain;
    // 587 是 STARTTLS 端口，465 是隐式 SSL。
    return config.smtpPort == 587 ? SocketType.starttls : SocketType.ssl;
  }

  Future<mail.MailClient> _connect({Duration timeout = const Duration(seconds: 20)}) async {
    if (!isReceiveReady) {
      throw MailException('邮箱账号收信配置不完整（地址/IMAP 服务器/密码）');
    }
    final client = mail.MailClient(_buildAccount(), isLogEnabled: false);
    await client.connect(timeout: timeout);
    return client;
  }

  /// 测试 IMAP 连通性，返回错误信息（null = 成功）。
  Future<String?> testConnection() async {
    mail.MailClient? client;
    try {
      client = await _connect(timeout: const Duration(seconds: 15));
      await client.listMailboxes();
      // SMTP 在发送时才真正建连，这里只验证收信配置。
      return null;
    } on mail.MailException catch (e) {
      return e.message ?? e.toString();
    } catch (e) {
      return e.toString();
    } finally {
      await client?.disconnect();
    }
  }

  /// 列出服务器上的文件夹名（供学习范围配置选择）。
  Future<List<String>> listFolders() async {
    final client = await _connect();
    try {
      final boxes = await client.listMailboxes();
      return boxes.map((b) => b.name).toList()..sort();
    } finally {
      await client.disconnect();
    }
  }

  /// 拉取最近邮件（信封 + 尽量带正文）。
  ///
  /// [folder] 为空表示 INBOX；[accountId] 标记邮件来源账号；
  /// [spaceAddresses] 为空间内全部账号地址，用于转发场景的原始收件识别。
  Future<List<EmailSummary>> fetchRecent({
    String folder = 'INBOX',
    int limit = 50,
    String accountId = '',
    Set<String> spaceAddresses = const {},
  }) async {
    final client = await _connect();
    try {
      final mailbox = folder == 'INBOX'
          ? await client.selectInbox()
          : await _selectByName(client, folder);
      if (mailbox == null) return [];
      final messages = await client.fetchMessages(
        mailbox: mailbox,
        count: limit,
        fetchPreference: mail.FetchPreference.fullWhenWithinSize,
      );
      return messages
          .map((m) => _toSummary(m, folder, accountId, spaceAddresses))
          .toList();
    } finally {
      await client.disconnect();
    }
  }

  Future<mail.Mailbox?> _selectByName(mail.MailClient client, String name) async {
    final boxes = await client.listMailboxes();
    for (final b in boxes) {
      if (b.name.toLowerCase() == name.toLowerCase()) {
        return await client.selectMailbox(b);
      }
    }
    return null;
  }

  /// 按主题线程键聚合：拉取来信前后若干往来（供草稿生成时的上下文）。
  Future<List<EmailSummary>> fetchThreadPeers(EmailSummary email) async {
    final results = <EmailSummary>[];
    for (final folder in {email.folder, 'INBOX', ..._sentCandidates()}) {
      try {
        final list = await fetchRecent(
            folder: folder, limit: 80, accountId: email.accountId);
        for (final m in list) {
          if (m.threadKey == email.threadKey && m.messageId != email.messageId) {
            results.add(m);
          }
        }
      } catch (_) {
        // 文件夹不存在等情况直接跳过。
      }
    }
    results.sort((a, b) => (a.parsedDate ?? DateTime(2000))
        .compareTo(b.parsedDate ?? DateTime(2000)));
    return results;
  }

  List<String> _sentCandidates() => const ['Sent', 'Sent Messages', '已发送'];

  /// SMTP 发送纯文本回复（带 In-Reply-To 头，便于客户端线程归组）。
  ///
  /// [ccAddresses] 用于转发场景：抄送客户写信的原始收件地址
  /// （如 support@g.com），保持客户视角线程一致。
  Future<void> sendReply({
    required String toAddress,
    required String subject,
    required String inReplyToMessageId,
    required String bodyText,
    List<String> ccAddresses = const [],
  }) async {
    if (!isSendReady) {
      throw MailException('邮箱账号发信配置不完整（地址/SMTP 服务器/密码）');
    }
    final client = await _connect();
    try {
      final replySubject =
          subject.toLowerCase().startsWith('re:') ? subject : 'Re: $subject';
      final builder = mail.MessageBuilder()
        ..from = [
          mail.MailAddress(
              config.displayName.isEmpty ? null : config.displayName,
              config.email),
        ]
        ..to = [mail.MailAddress(null, toAddress)]
        ..subject = replySubject
        ..text = bodyText;
      if (ccAddresses.isNotEmpty) {
        builder.cc = [
          for (final a in ccAddresses)
            if (a.trim().isNotEmpty) mail.MailAddress(null, a.trim()),
        ];
      }
      builder.addHeader('in-reply-to', inReplyToMessageId);
      builder.addHeader(
          'references', inReplyToMessageId); // 简化：指向来信即可归线程
      final message = builder.buildMimeMessage();
      await client.sendMessage(message, appendToSent: true);
    } finally {
      await client.disconnect();
    }
  }

  EmailSummary _toSummary(mail.MimeMessage m, String folder, String accountId,
      Set<String> spaceAddresses) {
    final messageId = m.getHeaderValue('message-id') ??
        '<synthetic-$folder-${m.uid ?? m.guid ?? m.sequenceId ?? m.hashCode}>';
    final inReplyTo = m.getHeaderValue('in-reply-to');
    final referencesRaw = m.getHeaderValue('references') ?? '';
    final referencesIds = referencesRaw
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.startsWith('<'))
        .toList();
    final date = m.decodeDate() ?? m.envelope?.date ?? DateTime.now();
    final body = _extractBody(m);
    final toAddresses = (m.to ?? [])
        .map((a) => a.email)
        .whereType<String>()
        .toList();
    final ccAddresses = (m.cc ?? [])
        .map((a) => a.email)
        .whereType<String>()
        .toList();
    return EmailSummary(
      messageId: messageId,
      subject: m.decodeSubject() ?? '（无主题）',
      fromAddress: m.from?.first.email ?? m.envelope?.from?.first.email ?? '',
      toAddresses: toAddresses,
      date: date.toIso8601String(),
      folder: folder,
      bodyText: body,
      snippet: _snippet(body),
      inReplyTo: (inReplyTo != null && inReplyTo.isNotEmpty) ? inReplyTo : null,
      referencesIds: referencesIds,
      accountId: accountId,
      originalRecipients:
          detectForwardedRecipients([...toAddresses, ...ccAddresses], spaceAddresses),
    );
  }

  String _extractBody(mail.MimeMessage m) {
    final plain = m.decodeTextPlainPart();
    if (plain != null && plain.trim().isNotEmpty) return plain;
    final html = m.decodeTextHtmlPart();
    if (html != null) return _htmlToPlain(html);
    return '';
  }

  static String _htmlToPlain(String html) => html
      .replaceAll(RegExp(r'<(br|/p|/div|/tr)[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  String _snippet(String body) {
    final t = body.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= 120 ? t : t.substring(0, 120);
  }
}

class MailException implements Exception {
  MailException(this.message);

  final String message;

  @override
  String toString() => message;
}
