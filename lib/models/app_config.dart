/// 应用配置模型。
///
/// 非敏感配置持久化在 `config/app_config.yaml`；
/// 敏感信息（邮箱密码/授权码、LLM API Key）存放在 flutter_secure_storage，
/// 不进入 YAML 文件。
class AppConfig {
  const AppConfig({
    this.mail = const MailAccountConfig(),
    this.llm = const LlmConfig(),
    this.outputLanguage = 'English',
    this.learnFolders = const ['Sent'],
    this.learnMonths = 12,
    this.learnMaxPerFolder = 200,
  });

  final MailAccountConfig mail;
  final LlmConfig llm;

  /// 草稿输出语言（收件人看到的语言），默认英文。
  final String outputLanguage;

  /// 历史邮件学习时要读取的文件夹名（IMAP），默认已发送。
  final List<String> learnFolders;

  /// 学习时间范围（近 N 个月）。
  final int learnMonths;

  /// 每个文件夹最多拉取的邮件数。
  final int learnMaxPerFolder;

  Map<String, dynamic> toMap() => {
        'mail': mail.toMap(),
        'llm': llm.toMap(),
        'output_language': outputLanguage,
        'learn_folders': learnFolders,
        'learn_months': learnMonths,
        'learn_max_per_folder': learnMaxPerFolder,
      };

  static AppConfig fromMap(Map<dynamic, dynamic> map) => AppConfig(
        mail: MailAccountConfig.fromMap(map['mail'] ?? {}),
        llm: LlmConfig.fromMap(map['llm'] ?? {}),
        outputLanguage: map['output_language'] as String? ?? 'English',
        learnFolders: (map['learn_folders'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['Sent'],
        learnMonths: map['learn_months'] as int? ?? 12,
        learnMaxPerFolder: map['learn_max_per_folder'] as int? ?? 200,
      );

  AppConfig copyWith({
    MailAccountConfig? mail,
    LlmConfig? llm,
    String? outputLanguage,
    List<String>? learnFolders,
    int? learnMonths,
    int? learnMaxPerFolder,
  }) =>
      AppConfig(
        mail: mail ?? this.mail,
        llm: llm ?? this.llm,
        outputLanguage: outputLanguage ?? this.outputLanguage,
        learnFolders: learnFolders ?? this.learnFolders,
        learnMonths: learnMonths ?? this.learnMonths,
        learnMaxPerFolder: learnMaxPerFolder ?? this.learnMaxPerFolder,
      );
}

/// 邮箱账号（IMAP 收 + SMTP 发）。
class MailAccountConfig {
  const MailAccountConfig({
    this.email = '',
    this.displayName = '',
    this.imapHost = '',
    this.imapPort = 993,
    this.imapSecure = true,
    this.smtpHost = '',
    this.smtpPort = 465,
    this.smtpSecure = true,
  });

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

  bool get isConfigured =>
      email.isNotEmpty && imapHost.isNotEmpty && smtpHost.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'email': email,
        'display_name': displayName,
        'imap_host': imapHost,
        'imap_port': imapPort,
        'imap_secure': imapSecure,
        'smtp_host': smtpHost,
        'smtp_port': smtpPort,
        'smtp_secure': smtpSecure,
      };

  static MailAccountConfig fromMap(Map<dynamic, dynamic> map) =>
      MailAccountConfig(
        email: map['email'] as String? ?? '',
        displayName: map['display_name'] as String? ?? '',
        imapHost: map['imap_host'] as String? ?? '',
        imapPort: map['imap_port'] as int? ?? 993,
        imapSecure: map['imap_secure'] as bool? ?? true,
        smtpHost: map['smtp_host'] as String? ?? '',
        smtpPort: map['smtp_port'] as int? ?? 465,
        smtpSecure: map['smtp_secure'] as bool? ?? true,
      );

  MailAccountConfig copyWith({
    String? email,
    String? displayName,
    String? imapHost,
    int? imapPort,
    bool? imapSecure,
    String? smtpHost,
    int? smtpPort,
    bool? smtpSecure,
  }) =>
      MailAccountConfig(
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        imapHost: imapHost ?? this.imapHost,
        imapPort: imapPort ?? this.imapPort,
        imapSecure: imapSecure ?? this.imapSecure,
        smtpHost: smtpHost ?? this.smtpHost,
        smtpPort: smtpPort ?? this.smtpPort,
        smtpSecure: smtpSecure ?? this.smtpSecure,
      );
}

/// 大模型配置（OpenAI 兼容协议）。
class LlmConfig {
  const LlmConfig({
    this.baseUrl = '',
    this.model = '',
    this.temperature = 0.3,
    this.maxTokens = 2048,
    this.timeoutSeconds = 120,
  });

  /// API 基础地址，通常以 /v1 结尾，例如 https://api.openai.com/v1 。
  final String baseUrl;

  /// 模型名称，例如 gpt-4o-mini、deepseek-chat 等。
  final String model;

  final double temperature;
  final int maxTokens;
  final int timeoutSeconds;

  bool get isConfigured => baseUrl.isNotEmpty && model.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'base_url': baseUrl,
        'model': model,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'timeout_seconds': timeoutSeconds,
      };

  static LlmConfig fromMap(Map<dynamic, dynamic> map) => LlmConfig(
        baseUrl: map['base_url'] as String? ?? '',
        model: map['model'] as String? ?? '',
        temperature: (map['temperature'] as num?)?.toDouble() ?? 0.3,
        maxTokens: map['max_tokens'] as int? ?? 2048,
        timeoutSeconds: map['timeout_seconds'] as int? ?? 120,
      );

  LlmConfig copyWith({
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    int? timeoutSeconds,
  }) =>
      LlmConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      );
}
