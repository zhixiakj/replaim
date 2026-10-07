/// 轻量邮件模型：enough_mail 的 MimeMessage 转成可序列化的应用模型，
/// 供收件箱列表、线程视图、历史学习与草稿生成使用。
class EmailSummary {
  const EmailSummary({
    required this.messageId,
    required this.subject,
    required this.fromAddress,
    required this.toAddresses,
    required this.date,
    required this.folder,
    this.bodyText = '',
    this.snippet = '',
    this.inReplyTo,
    this.referencesIds = const [],
    this.accountId = '',
    this.originalRecipients = const [],
    this.uid,
  });

  /// Message-ID 头（含尖括号）。极少数邮件缺失时以合成值兜底。
  final String messageId;
  final String subject;
  final String fromAddress;
  final List<String> toAddresses;

  /// ISO 字符串。
  final String date;

  /// 所在 IMAP 文件夹名，例如 INBOX / Sent。
  final String folder;

  /// 纯文本正文（可能为空，列表阶段只取 snippet）。
  final String bodyText;

  /// 正文摘要（列表展示用）。
  final String snippet;

  final String? inReplyTo;

  /// References 头解析出的 Message-ID 链。
  final List<String> referencesIds;

  /// 收信账号 ID（空间内哪个账号的邮箱收到这封邮件）。
  final String accountId;

  /// 转发场景检测出的原始收件地址（To/Cc 中不属于空间账号的地址），
  /// 回信时需要抄送，保持客户视角线程一致。
  final List<String> originalRecipients;

  /// 所在文件夹内的 IMAP UID，增量同步的合并与 lastUid 追踪用。
  final int? uid;

  DateTime? get parsedDate => DateTime.tryParse(date);

  /// 线程键：优先用 References/In-Reply-To 的根，否则用归一化主题。
  String get threadKey {
    final rootRef = referencesIds.isNotEmpty ? referencesIds.first : inReplyTo;
    if (rootRef != null && rootRef.isNotEmpty) return rootRef;
    return normalizedSubject;
  }

  /// 归一化主题：去掉 Re:/Fw: 前缀与空格，小写。
  String get normalizedSubject =>
      subject.replaceAll(RegExp(r'^\s*((re|fw|fwd|答复|转发)(\[\d+\])?:\s*)+',
              caseSensitive: false),
          '').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  /// 供 LLM 学习时展示的往来条目文本。
  String toLearningText() {
    final buf = StringBuffer();
    buf.writeln('--- 邮件 ---');
    buf.writeln('时间: $date');
    buf.writeln('发件人: $fromAddress');
    buf.writeln('主题: $subject');
    final body = bodyText.trim();
    buf.writeln(body.isEmpty ? '（无正文）' : body);
    return buf.toString();
  }

  Map<String, dynamic> toMap() => {
        'message_id': messageId,
        'subject': subject,
        'from_address': fromAddress,
        'to_addresses': toAddresses,
        'date': date,
        'folder': folder,
        'body_text': bodyText,
        'snippet': snippet,
        'in_reply_to': inReplyTo,
        'references_ids': referencesIds,
        'account_id': accountId,
        'original_recipients': originalRecipients,
        'uid': uid,
      };

  static EmailSummary fromMap(Map<dynamic, dynamic> map) => EmailSummary(
        messageId: map['message_id'] as String? ?? '',
        subject: map['subject'] as String? ?? '',
        fromAddress: map['from_address'] as String? ?? '',
        toAddresses: (map['to_addresses'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        date: map['date'] as String? ?? '',
        folder: map['folder'] as String? ?? '',
        bodyText: map['body_text'] as String? ?? '',
        snippet: map['snippet'] as String? ?? '',
        inReplyTo: map['in_reply_to'] as String?,
        referencesIds: (map['references_ids'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        accountId: map['account_id'] as String? ?? '',
        originalRecipients: (map['original_recipients'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        uid: map['uid'] as int?,
      );
}
