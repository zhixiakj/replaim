/// 邮箱空间：一个独立的业务上下文（如一个店铺 / 品牌）。
///
/// 一个空间内共用一套回复规则与知识库，可配置多个邮箱账号（收信 / 发信），
/// 并引用一个全局 LLM Profile。数据按 `spaces/<id>/` 目录分区存储。
class MailSpace {
  MailSpace({
    required this.id,
    required this.name,
    List<MailAccountConfig> accounts = const [],
    this.llmProfileId,
    this.defaultSendAccountId,
    this.outputLanguage = 'English',
    this.learnMonths = 12,
    this.learnMaxPerFolder = 200,
    DateTime? createdAt,
  })  : accounts = List.of(accounts),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;

  /// 空间内的邮箱账号（可变：管理界面编辑后整体落盘）。
  final List<MailAccountConfig> accounts;

  /// 引用的全局 LLM Profile ID（见 LlmProfile）。
  String? llmProfileId;

  /// 默认发信账号 ID：收信账号未开发信能力时的回落。
  String? defaultSendAccountId;

  /// 草稿输出语言（收件人看到的语言）。
  String outputLanguage;

  /// 学习时间范围（近 N 个月）。
  int learnMonths;

  /// 每个文件夹最多拉取的邮件数。
  int learnMaxPerFolder;

  final DateTime createdAt;

  List<MailAccountConfig> get receiveAccounts =>
      accounts.where((a) => a.receiveEnabled).toList();

  List<MailAccountConfig> get sendAccounts =>
      accounts.where((a) => a.sendEnabled).toList();

  /// 空间内全部账号的邮箱地址（小写，用于转发识别等）。
  Set<String> get accountAddresses => {
        for (final a in accounts)
          if (a.email.trim().isNotEmpty) a.email.trim().toLowerCase(),
      };

  MailAccountConfig? accountById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// 发信账号解析：优先收信账号自己发（线程最自然）；
  /// 收信账号未开发信时回落到 [defaultSendAccountId]；再回落到任一可发信账号。
  MailAccountConfig? resolveSender(String? receivingAccountId) {
    final receiving = accountById(receivingAccountId);
    if (receiving != null && receiving.sendEnabled) return receiving;
    final fallback = accountById(defaultSendAccountId);
    if (fallback != null && fallback.sendEnabled) return fallback;
    for (final a in accounts) {
      if (a.sendEnabled) return a;
    }
    return null;
  }

  /// 注意：模型字段可变（管理界面就地编辑后调用 SpaceStore.save 落盘），
  /// 不提供 copyWith。
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'llm_profile_id': llmProfileId,
        'default_send_account_id': defaultSendAccountId,
        'output_language': outputLanguage,
        'learn_months': learnMonths,
        'learn_max_per_folder': learnMaxPerFolder,
        'created_at': createdAt.toIso8601String(),
      };

  /// 旧版把历史学习文件夹放在空间级（learn_folders 键）；现改为按账号配置，
  /// 读取时把旧空间级值继承给每个账号（账号自身键优先），实现一次性迁移：
  /// 老数据首次打开即生效，保存后空间级旧键自然消失。
  static MailSpace fromMap(Map<dynamic, dynamic> map) {
    final legacyLearnFolders =
        (map['learn_folders'] as List?)?.map((e) => e.toString()).toList();
    return MailSpace(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '未命名空间',
      accounts: (map['accounts'] as List? ?? [])
          .map((e) => MailAccountConfig.fromMap(e as Map,
              fallbackLearnFolders: legacyLearnFolders))
          .toList(),
      llmProfileId: map['llm_profile_id'] as String?,
      defaultSendAccountId: map['default_send_account_id'] as String?,
      outputLanguage: map['output_language'] as String? ?? 'English',
      learnMonths: map['learn_months'] as int? ?? 12,
      learnMaxPerFolder: map['learn_max_per_folder'] as int? ?? 200,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
    );
  }
}

/// 邮箱账号（IMAP 收 + SMTP 发），归属某个空间。
class MailAccountConfig {
  const MailAccountConfig({
    this.id = '',
    this.email = '',
    this.displayName = '',
    this.imapHost = '',
    this.imapPort = 993,
    this.imapSecure = true,
    this.smtpHost = '',
    this.smtpPort = 465,
    this.smtpSecure = true,
    this.receiveEnabled = true,
    this.sendEnabled = true,
    this.learnFolders = const ['Sent'],
  });

  /// 账号 ID（acct_ 前缀），密码等敏感信息以此作为命名空间键。
  final String id;

  /// 邮箱地址，同时作为 IMAP/SMTP 登录用户名。
  final String email;

  /// 发件显示名。
  final String displayName;

  final String imapHost;
  final int imapPort;

  /// true = SSL/TLS（993），false = 明文（不推荐）。
  final bool imapSecure;

  final String smtpHost;
  final int smtpPort;

  /// true = SSL/TLS（465），false = STARTTLS 由端口决定（587 时通常为 true + STARTTLS）。
  final bool smtpSecure;

  /// 是否参与收信（IMAP 拉取收件箱）。
  final bool receiveEnabled;

  /// 是否可用于发信（SMTP）。
  final bool sendEnabled;

  /// 该账号历史学习要读取的文件夹名（IMAP），因邮箱服务商而异：
  /// Gmail 为 [Gmail]/Sent Mail（中文账号为 [Gmail]/已发送邮件），
  /// QQ/163 为 Sent Messages，Outlook 为 Sent。默认 ['Sent']，
  /// 实际解析见 MailService.matchMailboxName 的三轮匹配。
  final List<String> learnFolders;

  /// 收信配置是否完整（密码另存于安全存储，由 MailService 层校验）。
  bool get isReceiveConfigured =>
      email.isNotEmpty && imapHost.isNotEmpty;

  /// 发信配置是否完整（密码另存于安全存储，由 MailService 层校验）。
  bool get isSendConfigured =>
      email.isNotEmpty && smtpHost.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'imap_host': imapHost,
        'imap_port': imapPort,
        'imap_secure': imapSecure,
        'smtp_host': smtpHost,
        'smtp_port': smtpPort,
        'smtp_secure': smtpSecure,
        'receive_enabled': receiveEnabled,
        'send_enabled': sendEnabled,
        'learn_folders': learnFolders,
      };

  static MailAccountConfig fromMap(Map<dynamic, dynamic> map,
          {List<String>? fallbackLearnFolders}) =>
      MailAccountConfig(
        id: map['id'] as String? ?? '',
        email: map['email'] as String? ?? '',
        displayName: map['display_name'] as String? ?? '',
        imapHost: map['imap_host'] as String? ?? '',
        imapPort: map['imap_port'] as int? ?? 993,
        imapSecure: map['imap_secure'] as bool? ?? true,
        smtpHost: map['smtp_host'] as String? ?? '',
        smtpPort: map['smtp_port'] as int? ?? 465,
        smtpSecure: map['smtp_secure'] as bool? ?? true,
        receiveEnabled: map['receive_enabled'] as bool? ?? true,
        sendEnabled: map['send_enabled'] as bool? ?? true,
        learnFolders: (map['learn_folders'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            fallbackLearnFolders ??
            const ['Sent'],
      );

  MailAccountConfig copyWith({
    String? id,
    String? email,
    String? displayName,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    String? smtpHost,
    int? smtpPort,
    bool? smtpSecure,
    bool? receiveEnabled,
    bool? sendEnabled,
    List<String>? learnFolders,
  }) =>
      MailAccountConfig(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        imapHost: imapHost ?? this.imapHost,
        imapPort: imapPort ?? this.imapPort,
        imapSecure: imapSecure ?? this.imapSecure,
        smtpHost: smtpHost ?? this.smtpHost,
        smtpPort: smtpPort ?? this.smtpPort,
        smtpSecure: smtpSecure ?? this.smtpSecure,
        receiveEnabled: receiveEnabled ?? this.receiveEnabled,
        sendEnabled: sendEnabled ?? this.sendEnabled,
        learnFolders: learnFolders ?? this.learnFolders,
      );
}

/// 检测「转发生成的原始收件地址」。
///
/// 场景：客户写信给 support@g.com（未配置进应用），服务器把信转发到
/// 已配置的 a@g.com。此时邮件 To/Cc 头仍是 support@g.com（服务器转发
/// 不改写收件头），而实际投递邮箱是 a@g.com。
///
/// 判定：To/Cc 中的地址减去本空间全部账号地址，剩下的外部地址即
/// 客户写信的原始目的地。回信时用收信账号发送并抄送这些地址，
/// 客户视角的线程保持一致。结果可能包含客户自己抄送的第三方
/// （等同 reply-all 语义），发送前可在草稿页增删。
List<String> detectForwardedRecipients(
  List<String> toCcAddresses,
  Set<String> spaceAccountAddresses,
) {
  final space = spaceAccountAddresses
      .map((e) => e.trim().toLowerCase())
      .toSet();
  final out = <String>{};
  for (final raw in toCcAddresses) {
    final e = raw.trim().toLowerCase();
    if (e.isNotEmpty && !space.contains(e)) out.add(e);
  }
  return out.toList()..sort();
}
