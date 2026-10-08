import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:enough_mail/enough_mail.dart' show SocketType;

import '../models/email_summary.dart';
import '../models/mail_space.dart';
import 'stores.dart';

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
      return await _fetchSummaries(
          client, mailbox, folder, limit, accountId, spaceAddresses);
    } finally {
      await client.disconnect();
    }
  }

  /// 增量同步指定文件夹（默认 INBOX，配合 InboxCacheStore 的缓存状态）：
  /// - 无缓存 / UIDVALIDITY 与服务器不一致 → 全量拉最近 [limit] 封重建；
  /// - uidNext 显示积压新邮件超过 [limit] 封（离线太久）→ 同样走全量；
  /// - uidNext 显示没有新邮件 → 一条 FETCH 都不发，缓存原样返回；
  /// - 其余情况只 FETCH lastUid 之后的新邮件（含正文），与缓存合并去重。
  ///
  /// [folder] 为 'INBOX' 时直选收件箱；否则按名字解析真实文件夹
  /// （如 Gmail 的 '[Gmail]/Sent Mail'），结果与邮件标签都用解析后的名字。
  Future<InboxSyncResult> fetchIncremental({
    String folder = 'INBOX',
    int limit = 50,
    String accountId = '',
    Set<String> spaceAddresses = const {},
    int? cachedUidValidity,
    int? cachedLastUid,
    List<EmailSummary> cachedMessages = const [],
  }) async {
    final client = await _connect();
    try {
      final mailbox = folder == 'INBOX'
          ? await client.selectInbox()
          : await _selectByName(client, folder);
      // INBOX 恒为 'INBOX'（与旧缓存标签一致）；其它文件夹用服务器真实名，
      // 作为缓存游标与去重键的一部分，避免与 INBOX 的 UID 撞车。
      final folderLabel = folder == 'INBOX' ? 'INBOX' : mailbox.name;
      final uidValidity = mailbox.uidValidity;
      final uidNext = mailbox.uidNext;
      final incrementalOk = uidValidity != null &&
          cachedUidValidity == uidValidity &&
          cachedLastUid != null &&
          cachedLastUid > 0 &&
          cachedMessages.isNotEmpty;
      final backlog = (uidNext == null || cachedLastUid == null)
          ? null
          : uidNext - 1 - cachedLastUid;
      if (!incrementalOk || (backlog != null && backlog > limit)) {
        final fresh = await _fetchSummaries(
            client, mailbox, folderLabel, limit, accountId, spaceAddresses);
        return InboxSyncResult(
          messages: fresh,
          folder: folderLabel,
          uidValidity: uidValidity,
          lastUid: _maxUid(fresh) ?? cachedLastUid,
          fullResync: true,
        );
      }
      if (backlog != null && backlog <= 0) {
        return InboxSyncResult(
          messages: cachedMessages,
          folder: folderLabel,
          uidValidity: uidValidity,
          lastUid: cachedLastUid,
        );
      }
      final fetched = await client.fetchMessageSequence(
        mail.MessageSequence.fromRangeToLast(cachedLastUid + 1,
            isUidSequence: true),
        fetchPreference: mail.FetchPreference.fullWhenWithinSize,
      );
      // UID x:* 在 x 超过现存最大 UID 时仍会返回最后一封，需按 UID 过滤。
      final fresh = fetched
          .where((m) => (m.uid ?? 0) > cachedLastUid)
          .map((m) => _toSummary(m, folderLabel, accountId, spaceAddresses))
          .toList();
      final merged = mergeInboxMessages(cachedMessages, fresh, limit: limit);
      return InboxSyncResult(
        messages: merged,
        folder: folderLabel,
        uidValidity: uidValidity,
        lastUid: _maxUid(fresh) ?? cachedLastUid,
      );
    } finally {
      await client.disconnect();
    }
  }

  /// 选中文件夹后拉取最近 [limit] 封并转成应用模型。
  Future<List<EmailSummary>> _fetchSummaries(
    mail.MailClient client,
    mail.Mailbox mailbox,
    String folder,
    int limit,
    String accountId,
    Set<String> spaceAddresses,
  ) async {
    final messages = await client.fetchMessages(
      mailbox: mailbox,
      count: limit,
      fetchPreference: mail.FetchPreference.fullWhenWithinSize,
    );
    return messages
        .map((m) => _toSummary(m, folder, accountId, spaceAddresses))
        .toList();
  }

  Future<mail.Mailbox> _selectByName(mail.MailClient client, String name) async {
    final boxes = await client.listMailboxes();
    final names = boxes.map((b) => b.name).toList();
    final matched = matchMailboxName(names, name);
    if (matched == null) {
      throw FolderNotFoundException(_folderNotFoundMessage(name, names));
    }
    return client.selectMailbox(boxes.firstWhere((b) => b.name == matched));
  }

  /// 按文件夹与 UID 单封拉取完整邮件并转成应用模型。
  ///
  /// 详情弹窗按需补取用：老缓存邮件在模型扩展（cc / 发信认证信息）之前落盘，
  /// 增量同步只拉新 UID 不会再处理它们，这里按 UID 现拉一次补齐。
  /// 邮件在服务器上不存在返回 null；连接 / 文件夹错误向上抛，由调用方兜底。
  Future<EmailSummary?> fetchByUid({
    required String folder,
    required int uid,
    String accountId = '',
    Set<String> spaceAddresses = const {},
  }) async {
    final client = await _connect();
    try {
      // 选中动作本身即为目的（后续 UID FETCH 作用于当前文件夹）。
      if (folder == 'INBOX') {
        await client.selectInbox();
      } else {
        await _selectByName(client, folder);
      }
      final sequence = mail.MessageSequence(isUidSequence: true)..add(uid);
      final fetched = await client.fetchMessageSequence(
        sequence,
        fetchPreference: mail.FetchPreference.fullWhenWithinSize,
      );
      // folder 入参即缓存里存的解析后服务器名，直接作为标签保持一致。
      for (final m in fetched) {
        if (m.uid == uid) {
          return _toSummary(m, folder, accountId, spaceAddresses);
        }
      }
      return null;
    } finally {
      await client.disconnect();
    }
  }

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
    final authResults = m.getHeaderValue('authentication-results');
    return EmailSummary(
      messageId: messageId,
      subject: m.decodeSubject() ?? '（无主题）',
      fromAddress: m.from?.first.email ?? m.envelope?.from?.first.email ?? '',
      toAddresses: toAddresses,
      ccAddresses: ccAddresses,
      mailedBy: parseMailedBy(authResults),
      signedBy: parseSignedBy(authResults),
      date: date.toIso8601String(),
      folder: folder,
      bodyText: body,
      snippet: _snippet(body),
      inReplyTo: (inReplyTo != null && inReplyTo.isNotEmpty) ? inReplyTo : null,
      referencesIds: referencesIds,
      accountId: accountId,
      originalRecipients:
          detectForwardedRecipients([...toAddresses, ...ccAddresses], spaceAddresses),
      uid: m.uid,
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

/// 服务器上不存在该文件夹（message 内含现有文件夹列表提示），
/// 供调用方区分「跳过即可」与「需要报错」的失败。
class FolderNotFoundException extends MailException {
  FolderNotFoundException(super.message);
}

String _folderNotFoundMessage(String name, List<String> names) {
  final preview = names.take(10).join('、');
  final more = names.length > 10 ? ' 等共 ${names.length} 个' : '';
  return '服务器上找不到文件夹「$name」（现有：$preview$more）';
}

/// 在服务器文件夹名列表中找到与 [want] 匹配的文件夹名，找不到返回 null。
///
/// 各家服务商对同一文件夹命名不同（Gmail 是 `[Gmail]/Sent Mail`、QQ 是
/// `Sent Messages`、网易是 `已发送`），因此按三轮优先级匹配，每轮先扫完
/// 全部候选再进入下一轮（保证「精确命中」优先于「排在前面的候选」）：
/// 1. 全名大小写不敏感全等；
/// 2. 叶子名全等（按 '/' / '.' 分层取末段，兼容 '[Gmail]/Sent Mail'、
///    'INBOX.Sent' 这类层级命名）；
/// 3. 「已发送」别名组归一化匹配，让配置 Sent 能命中各家命名。
String? matchMailboxName(List<String> mailboxNames, String want) {
  final wanted = _normalizeFolderName(want);
  if (wanted.isEmpty) return null;
  for (final name in mailboxNames) {
    if (_normalizeFolderName(name) == wanted) return name;
  }
  for (final name in mailboxNames) {
    if (_leafFolderName(name) == wanted) return name;
  }
  if (!_sentFolderAliases.contains(wanted)) return null;
  for (final name in mailboxNames) {
    if (_sentFolderAliases.contains(_leafFolderName(name))) return name;
  }
  return null;
}

String _normalizeFolderName(String name) => name.trim().toLowerCase();

String _leafFolderName(String name) {
  final normalized = _normalizeFolderName(name);
  final cut = [normalized.lastIndexOf('.'), normalized.lastIndexOf('/')]
      .reduce((a, b) => a > b ? a : b);
  return cut < 0 ? normalized : normalized.substring(cut + 1);
}

/// 「已发送」文件夹在各家服务商下的常见名字（归一化后）。
const Set<String> _sentFolderAliases = {
  'sent',
  'sent messages',
  'sent items',
  'sent mail',
  '已发送',
  '已发邮件',
};

/// 从 Authentication-Results 头解析 spf=pass 的发信域名（Gmail 的 mailed-by）。
///
/// 只信收件服务器的判定（spf=pass 才取 smtp.mailfrom 域名），不回退到
/// Return-Path 等客户端可伪造的头；无该头或未通过返回空串。
String parseMailedBy(String? authResults) {
  if (authResults == null) return '';
  for (final clause in authResults.split(';')) {
    if (!clause.trim().toLowerCase().startsWith('spf=pass')) continue;
    final match = RegExp(r'smtp\.mailfrom=([^\s;)]+)').firstMatch(clause);
    if (match == null) continue;
    final value = match.group(1)!;
    return value.contains('@') ? value.split('@').last : value;
  }
  return '';
}

/// 从 Authentication-Results 头解析 dkim=pass 的签名域名（Gmail 的 signed-by）。
/// 无该头或未通过返回空串。
String parseSignedBy(String? authResults) {
  if (authResults == null) return '';
  for (final clause in authResults.split(';')) {
    if (!clause.trim().toLowerCase().startsWith('dkim=pass')) continue;
    final match = RegExp(r'header\.d=([^\s;)]+)').firstMatch(clause);
    if (match != null) return match.group(1)!;
  }
  return '';
}

/// 一次文件夹增量同步的结果。
class InboxSyncResult {
  const InboxSyncResult({
    required this.messages,
    this.folder = 'INBOX',
    this.uidValidity,
    this.lastUid,
    this.fullResync = false,
  });

  /// 合并后的全量列表（≤ limit 封）。
  final List<EmailSummary> messages;

  /// 本次同步的文件夹（解析后的服务器真实名，如 '[Gmail]/Sent Mail'）。
  final String folder;

  final int? uidValidity;
  final int? lastUid;

  /// 本次走了全量重建路径（首次同步 / UIDVALIDITY 变化 / 积压超限）。
  final bool fullResync;
}

int? _maxUid(Iterable<EmailSummary> messages) {
  int? max;
  for (final m in messages) {
    final uid = m.uid;
    if (uid != null && (max == null || uid > max)) max = uid;
  }
  return max;
}
