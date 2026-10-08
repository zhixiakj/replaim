/// 常见邮箱服务商预设：按邮箱地址域名匹配，自动填充 IMAP/SMTP 服务器
/// 与「已发送」文件夹名，免去用户查文档手填。
///
/// 预置值只是更准的起点——各家对同一文件夹命名不同且可能随账号界面
/// 语言本地化，实际拉取仍以 MailService.matchMailboxName 的三轮匹配与
/// `\Sent` 特殊标记（detectSentFolder）兜底为准，均可手动修改。
class MailProviderPreset {
  const MailProviderPreset({
    required this.label,
    required this.domains,
    required this.imapHost,
    this.imapPort = 993,
    this.imapSecure = true,
    required this.smtpHost,
    this.smtpPort = 465,
    this.smtpSecure = true,
    required this.sentFolders,
  });

  final String label;
  final List<String> domains;

  final String imapHost;
  final int imapPort;
  final bool imapSecure;

  /// 587 端口按 MailService 的端口规则解释为 STARTTLS（465 为隐式 SSL）。
  final String smtpHost;
  final int smtpPort;
  final bool smtpSecure;

  /// 该服务商「已发送」文件夹的常见名字（可多个，作为学习文件夹候选）。
  final List<String> sentFolders;
}

const kMailProviderPresets = <MailProviderPreset>[
  // Gmail 的文件夹名随账号界面语言本地化，中英文都预置。
  MailProviderPreset(
    label: 'Gmail',
    domains: ['gmail.com', 'googlemail.com'],
    imapHost: 'imap.gmail.com',
    smtpHost: 'smtp.gmail.com',
    sentFolders: ['[Gmail]/Sent Mail', '[Gmail]/已发送邮件'],
  ),
  MailProviderPreset(
    label: 'Outlook / Hotmail',
    domains: ['outlook.com', 'hotmail.com', 'live.com', 'msn.com'],
    imapHost: 'outlook.office365.com',
    smtpHost: 'smtp.office365.com',
    smtpPort: 587,
    sentFolders: ['Sent', 'Sent Items'],
  ),
  MailProviderPreset(
    label: 'QQ 邮箱',
    domains: ['qq.com', 'foxmail.com'],
    imapHost: 'imap.qq.com',
    smtpHost: 'smtp.qq.com',
    sentFolders: ['Sent Messages'],
  ),
  MailProviderPreset(
    label: '网易 163',
    domains: ['163.com'],
    imapHost: 'imap.163.com',
    smtpHost: 'smtp.163.com',
    sentFolders: ['Sent Messages'],
  ),
  MailProviderPreset(
    label: '网易 126',
    domains: ['126.com'],
    imapHost: 'imap.126.com',
    smtpHost: 'smtp.126.com',
    sentFolders: ['Sent Messages'],
  ),
  MailProviderPreset(
    label: '网易 yeah.net',
    domains: ['yeah.net'],
    imapHost: 'imap.yeah.net',
    smtpHost: 'smtp.yeah.net',
    sentFolders: ['Sent Messages'],
  ),
  MailProviderPreset(
    label: 'iCloud',
    domains: ['icloud.com', 'me.com', 'mac.com'],
    imapHost: 'imap.mail.me.com',
    smtpHost: 'smtp.mail.me.com',
    smtpPort: 587,
    sentFolders: ['Sent Messages'],
  ),
  MailProviderPreset(
    label: 'Yahoo',
    domains: ['yahoo.com'],
    imapHost: 'imap.mail.yahoo.com',
    smtpHost: 'smtp.mail.yahoo.com',
    sentFolders: ['Sent'],
  ),
];

/// 按邮箱地址取预设（取 @ 后域名小写精确匹配），未知服务商返回 null。
MailProviderPreset? mailProviderPresetFor(String email) {
  final parts = email.trim().toLowerCase().split('@');
  if (parts.length < 2 || parts.last.isEmpty) return null;
  final domain = parts.last;
  for (final p in kMailProviderPresets) {
    if (p.domains.contains(domain)) return p;
  }
  return null;
}
