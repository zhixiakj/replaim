import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/date_format.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/messages.dart';
import '../../l10n/resolve_msg.dart';
import '../../models/mail_space.dart';
import '../../providers/app_providers.dart';
import '../../services/id_gen.dart';
import '../../services/mail_provider_presets.dart';
import '../../services/mail_service.dart';
import '../../services/microsoft_oauth.dart';

/// 空间管理：空间列表 + 空间详情（账号 / LLM 分配 / 默认发信账号 / 学习偏好）。
///
/// 一个空间内共用一套回复规则与知识库，可配置多个邮箱账号（收信 / 发信）；
/// 各数据页面（收件箱 / 规则库 / 知识库 / 学习 / 草稿）均按当前空间分区。
class SpacesPage extends ConsumerStatefulWidget {
  const SpacesPage({super.key});

  @override
  ConsumerState<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends ConsumerState<SpacesPage> {
  /// 本页正在编辑的空间（与「当前工作空间」是两个概念）。
  String? _editingId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacesState = ref.watch(spacesProvider);
    final cur = ref.watch(currentSpaceProvider);

    if (!spacesState.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final spaces = spacesState.spaces;
    if (spaces.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.spacesTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.spacesEmptyIntro,
            style: const TextStyle(height: 1.7),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createSpace(),
            icon: const Icon(Icons.add),
            label: Text(l10n.spacesCreateFirst),
          ),
        ],
      );
    }

    _editingId ??= cur.space?.id ?? spaces.first.id;
    final editing = spacesState.byId(_editingId) ?? spaces.first;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Text(l10n.spacesTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 12),
              Text(
                l10n.spacesCount(spaces.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _createSpace,
                icon: const Icon(Icons.add),
                label: Text(l10n.newSpaceTitle),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 280,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: spaces.length,
                  itemBuilder: (context, i) {
                    final s = spaces[i];
                    final isCurrent = s.id == cur.space?.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        selected: s.id == editing.id,
                        onTap: () => setState(() => _editingId = s.id),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.spacesCurrentBadge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          l10n.spacesAccountSummary(s.accounts.length,
                              s.receiveAccounts.length, s.sendAccounts.length),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: l10n.spacesDeleteTooltip,
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteSpace(s),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _SpaceDetail(key: ValueKey(editing.id), space: editing),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createSpace() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newSpaceTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.spaceNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonCreate),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final space = await ref.read(spacesProvider.notifier).create(name);
    await ref.read(spaceSelectionProvider.notifier).switchTo(space.id);
    if (mounted) setState(() => _editingId = space.id);
  }

  Future<void> _deleteSpace(MailSpace space) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.spacesDeleteTitle(space.name)),
        content: Text(l10n.spacesDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(spacesProvider.notifier).delete(space.id);
    if (mounted) setState(() => _editingId = null);
  }
}

/// 空间详情编辑：基本信息 + 学习偏好 + 账号管理。
class _SpaceDetail extends ConsumerStatefulWidget {
  const _SpaceDetail({super.key, required this.space});

  final MailSpace space;

  @override
  ConsumerState<_SpaceDetail> createState() => _SpaceDetailState();
}

class _SpaceDetailState extends ConsumerState<_SpaceDetail> {
  late final TextEditingController _name;
  late final TextEditingController _outputLanguage;
  late final TextEditingController _learnMonths;
  String _llmId = '';
  String _defaultSendId = '';

  /// 文本输入防抖自动保存（与草稿页同款 800ms）。
  Timer? _saveDebounce;
  bool _dirty = false;
  bool _suppressAutoSave = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _outputLanguage = TextEditingController();
    _learnMonths = TextEditingController();
    _initFrom(widget.space);
    // 初始装载完成后再挂监听，避免程序化赋值触发自动保存。
    _name.addListener(_onTextFieldChanged);
    _outputLanguage.addListener(_onTextFieldChanged);
    _learnMonths.addListener(_onTextFieldChanged);
  }

  void _initFrom(MailSpace s) {
    _suppressAutoSave = true;
    _name.text = s.name;
    _outputLanguage.text = s.outputLanguage;
    _learnMonths.text = '${s.learnMonths}';
    _llmId = s.llmProfileId ?? '';
    _defaultSendId = s.defaultSendAccountId ?? '';
    _suppressAutoSave = false;
  }

  void _onTextFieldChanged() {
    if (_suppressAutoSave) return;
    _dirty = true;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      _dirty = false;
      _persist(widget.space);
    });
  }

  @override
  void didUpdateWidget(covariant _SpaceDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换编辑对象时：先把旧空间可能还在防抖期内的输入落盘，再重新装载。
    // 同一空间的保存导致 rebuild 不回填（不打断输入）。
    if (oldWidget.space.id != widget.space.id) {
      _flushPending(oldWidget.space);
      _initFrom(widget.space);
    }
  }

  @override
  void dispose() {
    _flushPending(widget.space);
    _name.dispose();
    _outputLanguage.dispose();
    _learnMonths.dispose();
    super.dispose();
  }

  /// 立即取消防抖并落盘未保存的文本输入（切换空间 / 离开页面时兜底）。
  void _flushPending(MailSpace target) {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    if (!_dirty) return;
    _dirty = false;
    _persist(target);
  }

  Future<void> _persist(MailSpace target) async {
    final space = ref.read(spacesProvider).byId(target.id);
    if (space == null) return;
    space
      ..name = _name.text.trim().isEmpty ? space.name : _name.text.trim()
      ..outputLanguage = _outputLanguage.text.trim().isEmpty
          ? 'English'
          : _outputLanguage.text.trim()
      ..learnMonths =
          int.tryParse(_learnMonths.text.trim()) ?? space.learnMonths
      ..llmProfileId = _llmId.isEmpty ? null : _llmId
      ..defaultSendAccountId = _defaultSendId.isEmpty ? null : _defaultSendId;
    await ref.read(spacesProvider.notifier).save(space);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = widget.space;
    final profiles = ref.watch(llmProfilesProvider).profiles;
    final cur = ref.watch(currentSpaceProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.spacesDetailTitle(space.name),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (cur.space?.id != space.id)
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(spaceSelectionProvider.notifier)
                    .switchTo(space.id),
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.spacesSetCurrent),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ---------------- 基本信息 ----------------
        _section(
          context,
          title: l10n.spacesBasicInfoSection,
          children: [
            _textField(_name, l10n.spacesFieldName),
            _dropdown(
              value: _llmId,
              label: l10n.spacesAssignLlmLabel,
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.spacesLlmUnassigned)),
                for (final p in profiles)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(l10n.llmProfileTitle(p.name, p.config.model)),
                  ),
              ],
              onChanged: (v) => setState(() {
                _llmId = v ?? '';
                _persist(widget.space);
              }),
            ),
            _dropdown(
              value: _defaultSendId,
              label: l10n.spacesDefaultSendLabel,
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.spacesDefaultSendAuto)),
                for (final a in space.sendAccounts)
                  DropdownMenuItem(value: a.id, child: Text(a.email)),
              ],
              onChanged: (v) => setState(() {
                _defaultSendId = v ?? '';
                _persist(widget.space);
              }),
            ),
            _textField(_outputLanguage, l10n.spacesOutputLanguageLabel),
          ],
        ),

        // ---------------- 学习偏好 ----------------
        _section(
          context,
          title: l10n.spacesLearnPrefsSection,
          children: [
            _textField(_learnMonths, l10n.spacesLearnMonthsLabel, num: true),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.spacesLearnFoldersHint,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),

        // ---------------- 账号管理 ----------------
        _section(
          context,
          title: l10n.spacesAccountsSection(space.accounts.length),
          subtitle: l10n.spacesAccountsSubtitle,
          children: [
            if (space.accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.spacesNoAccounts,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              for (var i = 0; i < space.accounts.length; i++)
                _AccountTile(
                  account: space.accounts[i],
                  isDefaultSender:
                      space.defaultSendAccountId == space.accounts[i].id,
                  onEdit: () => _editAccount(space.accounts[i]),
                  onDelete: () => _deleteAccount(space.accounts[i]),
                  onToggleEnabled: (v) =>
                      _toggleAccountEnabled(space.accounts[i], v),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _editAccount(null),
              icon: const Icon(Icons.add),
              label: Text(l10n.spacesAddAccount),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Center(
          child: Text(
            l10n.spacesAutoSaved,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _editAccount(MailAccountConfig? existing) async {
    final space = ref.read(spacesProvider).byId(widget.space.id);
    if (space == null) return;
    await showDialog(
      context: context,
      builder: (context) => _AccountDialog(
        space: space,
        existing: existing,
        onSaved: (account, password, oauthToken) async {
          final fresh = ref.read(spacesProvider).byId(space.id);
          if (fresh == null) return;
          final i = fresh.accounts.indexWhere((a) => a.id == account.id);
          if (i >= 0) {
            fresh.accounts[i] = account;
          } else {
            fresh.accounts.add(account);
          }
          if (!account.sendEnabled &&
              fresh.defaultSendAccountId == account.id) {
            fresh.defaultSendAccountId = null;
          }
          await ref.read(spacesProvider.notifier).save(fresh);
          if (password != null && password.isNotEmpty) {
            await ref
                .read(secretsProvider.notifier)
                .saveMailPassword(account.id, password);
          }
          if (account.authType == kAuthTypeOauth) {
            if (oauthToken != null) {
              await ref
                  .read(secretsProvider.notifier)
                  .saveMailOauth(account.id, oauthToken.toString());
            }
          } else {
            // 切回密码模式：清掉旧 OAuth 令牌，避免残留失效凭证。
            await ref.read(secretsProvider.notifier).clearMailOauth(account.id);
          }
        },
      ),
    );
    if (mounted) setState(() {});
  }

  /// 列表里直接启停账号：停用即整体退出收信 / 发信 / 学习（配置保留）。
  /// 手动重新启用不做凭证校验：用户明确意图，配置不完整时由收件箱同步报错兜底。
  Future<void> _toggleAccountEnabled(MailAccountConfig account, bool v) async {
    final space = ref.read(spacesProvider).byId(widget.space.id);
    if (space == null) return;
    final i = space.accounts.indexWhere((a) => a.id == account.id);
    if (i < 0) return;
    space.accounts[i] = account.copyWith(enabled: v);
    if (!v && space.defaultSendAccountId == account.id) {
      space.defaultSendAccountId = null;
    }
    await ref.read(spacesProvider.notifier).save(space);
    if (mounted) setState(() {});
  }

  Future<void> _deleteAccount(MailAccountConfig account) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.spacesDeleteAccountTitle(account.email)),
        content: Text(l10n.spacesDeleteAccountContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final space = ref.read(spacesProvider).byId(widget.space.id);
    if (space == null) return;
    space.accounts.removeWhere((a) => a.id == account.id);
    if (space.defaultSendAccountId == account.id) {
      space.defaultSendAccountId = null;
    }
    await ref.read(spacesProvider.notifier).save(space);
    await ref.read(secretsProvider.notifier).removeAccount(account.id);
    if (mounted) setState(() {});
  }

  Widget _section(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController c,
    String label, {
    bool num = false,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: num ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Widget _dropdown({
    required String value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    ),
  );
}

/// 账号卡片：邮箱 + 启停开关 + 收/发能力徽标 + 编辑 / 删除。
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isDefaultSender,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  final MailAccountConfig account;
  final bool isDefaultSender;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        !account.enabled
            ? Icons.pause_circle_outline
            : (account.receiveEnabled && account.sendEnabled
                  ? Icons.mark_email_unread
                  : (account.receiveEnabled
                        ? Icons.move_to_inbox
                        : Icons.outgoing_mail)),
        size: 20,
        color: account.enabled
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
      ),
      title: Text(
        account.displayName.isEmpty
            ? account.email
            : '${account.displayName} <${account.email}>',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (!account.enabled) _badge(context, l10n.accountDisabledBadge, Colors.grey),
            _badge(
              context,
              account.receiveEnabled ? l10n.accountReceiveBadge : l10n.accountNoReceiveBadge,
              account.receiveEnabled ? Colors.green : Colors.grey,
            ),
            _badge(
              context,
              account.sendEnabled ? l10n.accountSendBadge : l10n.accountNoSendBadge,
              account.sendEnabled ? Colors.blue : Colors.grey,
            ),
            if (isDefaultSender) _badge(context, l10n.accountDefaultSendBadge, Colors.deepOrange),
            _badge(
              context,
              l10n.accountLearnFoldersBadge(account.learnFolders.join(l10n.commonJoinSeparator)),
              Colors.deepPurple,
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: account.enabled,
            onChanged: onToggleEnabled,
          ),
          IconButton(
            tooltip: l10n.commonEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: color.withValues(alpha: 1)),
    ),
  );
}

/// 添加 / 编辑账号对话框。
class _AccountDialog extends ConsumerStatefulWidget {
  const _AccountDialog({
    required this.space,
    required this.existing,
    required this.onSaved,
  });

  final MailSpace space;
  final MailAccountConfig? existing;
  final Future<void> Function(
    MailAccountConfig account,
    String? password,
    mail.OauthToken? oauthToken,
  )
  onSaved;

  @override
  ConsumerState<_AccountDialog> createState() => _AccountDialogState();
}

/// 账号对话框测试结果的展示级别（决定红/橙/绿字色，不靠文案内容判断）。
enum _TestResultKind { none, ok, warn, error }

class _AccountDialogState extends ConsumerState<_AccountDialog> {
  late final TextEditingController _email;
  late final TextEditingController _displayName;
  late final TextEditingController _imapHost;
  late final TextEditingController _imapPort;
  late final TextEditingController _smtpHost;
  late final TextEditingController _smtpPort;
  late final TextEditingController _password;
  late final TextEditingController _learnFolders;
  late final TextEditingController _oauthClientId;

  bool _imapSecure = true;
  bool _smtpSecure = true;
  bool _enabled = true;
  bool _receiveEnabled = true;
  bool _sendEnabled = true;
  bool _testing = false;
  String? _testResult;
  _TestResultKind _testResultKind = _TestResultKind.none;

  /// 本次会话最近一次「测试连接」是否成功（null = 尚未测试）。
  /// 不复用 _testResult 字符串：它还会被授权 / 校验消息复用，判定不可靠。
  bool? _lastTestOk;

  /// 编辑时钥匙串里是否已存该账号的密码（空输入是否等于「缺密码」）。
  bool _hadStoredPassword = false;

  /// OAuth2 登录（Outlook 必需）还是密码 / 授权码。
  bool _useOAuth = false;

  /// 本次会话里刚授权、尚未保存的 token（测试连接 / 保存时用）。
  mail.OauthToken? _pendingToken;

  /// 授权流程进行中（浏览器等待用户操作）。
  bool _authorizing = false;

  /// 登录方式是否被用户手动改过；未改过时允许预设自动切换。
  bool _authTouched = false;

  /// 当前选中 tab：0 = 收信（IMAP），1 = 发信（SMTP）。
  int _tabIndex = 0;

  /// 服务器地址 / 学习文件夹是否被用户手动改过；未改过时允许按邮箱
  /// 域名自动套用服务商预设（编辑已有账号时视为已手动定制，不覆盖）。
  bool _hostsTouched = false;
  bool _foldersTouched = false;

  /// 已存密码的占位掩码（配合 obscureText 显示为一排圆点）。
  static const _pwdMask = '••••••••';

  /// 剔除掩码字符后的有效输入；为空表示沿用旧密码。
  ///
  /// 真实授权码不含 '•'，所以无论是完整掩码、删了几位还是在掩码后追加
  /// 输入，剔除后得到的都恰好是用户真正敲入的内容。
  String? get _effectivePassword {
    final cleaned = _password.text.replaceAll('•', '');
    return cleaned.isEmpty ? null : cleaned;
  }

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _email = TextEditingController(text: m?.email ?? '');
    _displayName = TextEditingController(text: m?.displayName ?? '');
    _imapHost = TextEditingController(text: m?.imapHost ?? '');
    _imapPort = TextEditingController(text: '${m?.imapPort ?? 993}');
    _smtpHost = TextEditingController(text: m?.smtpHost ?? '');
    _smtpPort = TextEditingController(text: '${m?.smtpPort ?? 465}');
    _password = TextEditingController();
    _learnFolders = TextEditingController(
      text: m?.learnFolders.join(', ') ?? '',
    );
    _oauthClientId = TextEditingController(text: m?.oauthClientId ?? '');
    if (m != null &&
        (ref.read(secretsProvider).mailPasswords[m.id] ?? '').isNotEmpty) {
      _password.text = _pwdMask;
      _hadStoredPassword = true;
    }
    _imapSecure = m?.imapSecure ?? true;
    _smtpSecure = m?.smtpSecure ?? true;
    _enabled = m?.enabled ?? true;
    _receiveEnabled = m?.receiveEnabled ?? true;
    _sendEnabled = m?.sendEnabled ?? true;
    _useOAuth = m?.authType == kAuthTypeOauth;
    _hostsTouched = m != null;
    _foldersTouched = m != null;
    _authTouched = m != null;
    // 新建账号时：输入到完整邮箱地址即自动套用服务商预设。
    _email.addListener(_applyPreset);
  }

  @override
  void dispose() {
    _email.removeListener(_applyPreset);
    for (final c in [
      _email,
      _displayName,
      _imapHost,
      _imapPort,
      _smtpHost,
      _smtpPort,
      _password,
      _learnFolders,
      _oauthClientId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// 邮箱地址命中服务商预设时，自动填充服务器地址/端口/加密与预置的
  /// 已发送文件夹名（只填未被手动改过的字段）。
  void _applyPreset() {
    final preset = mailProviderPresetFor(_email.text);
    if (preset == null) return;
    if (!_hostsTouched) {
      _imapHost.text = preset.imapHost;
      _imapPort.text = '${preset.imapPort}';
      _smtpHost.text = preset.smtpHost;
      _smtpPort.text = '${preset.smtpPort}';
      setState(() {
        _imapSecure = preset.imapSecure;
        _smtpSecure = preset.smtpSecure;
      });
    }
    if (!_foldersTouched) {
      _learnFolders.text = preset.sentFolders.join(', ');
    }
    // Outlook 等预设要求 OAuth2（微软已禁用密码登录）。
    if (!_authTouched && preset.useOAuth != _useOAuth) {
      setState(() => _useOAuth = preset.useOAuth);
    }
  }

  /// 逗号分隔输入解析为文件夹名列表（去空白，忽略空段）。
  List<String> _parseFolders() => _learnFolders.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  MailAccountConfig _buildFromForm() =>
      (widget.existing ?? MailAccountConfig(id: newAccountId())).copyWith(
        email: _email.text.trim(),
        displayName: _displayName.text.trim(),
        imapHost: _imapHost.text.trim(),
        imapPort: int.tryParse(_imapPort.text.trim()) ?? 993,
        imapSecure: _imapSecure,
        smtpHost: _smtpHost.text.trim(),
        smtpPort: int.tryParse(_smtpPort.text.trim()) ?? 465,
        smtpSecure: _smtpSecure,
        enabled: _enabled,
        receiveEnabled: _receiveEnabled,
        sendEnabled: _sendEnabled,
        learnFolders: _parseFolders().isEmpty
            ? const ['Sent']
            : _parseFolders(),
        authType: _useOAuth ? kAuthTypeOauth : kAuthTypePassword,
        oauthClientId: _oauthClientId.text.trim(),
      );

  /// 凭证未就绪 / 本次会话连接未成功时返回停用原因（保存仍放行，
  /// 账号自动置为停用状态）；返回 null 表示可按开关状态保存。
  /// 测试成功不自动启用：启用与否尊重开关，避免意外启用特意停用的账号。
  String? _forcedOffReason(AppLocalizations l10n) {
    if (_useOAuth) {
      if (!_hasOAuthToken) return l10n.spacesForcedOffNoOauth;
    } else if (_effectivePassword == null && !_hadStoredPassword) {
      return l10n.spacesForcedOffNoPassword;
    }
    if (_lastTestOk == false) return l10n.spacesForcedOffTestFailed;
    return null;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.spacesErrEmailRequired)));
      return;
    }
    // 不强制连接成功：未就绪的账号照常保存，只是自动停用，可稍后补齐再启用。
    final offReason = _forcedOffReason(l10n);
    var account = _buildFromForm();
    if (offReason != null) account = account.copyWith(enabled: false);
    final password = _effectivePassword;
    // 对话框即将关闭：先取根级 messenger 与测试用凭证，保存后再异步核对。
    final messenger = ScaffoldMessenger.of(context);
    final svc = _mailServiceFor(account);
    Navigator.pop(context);
    if (offReason != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.spacesSavedDisabled(account.email, offReason))),
      );
    }
    await widget.onSaved(account, password, _pendingToken);
    unawaited(_validateFolders(messenger, l10n, account, svc));
  }

  /// 按当前表单状态组装 MailService（OAuth 模式带刚授权的待存 token，
  /// 密码模式带表单里新输入的密码），供测试 / 保存后核对复用。
  MailService _mailServiceFor(MailAccountConfig account) => ref
      .read(secretsProvider.notifier)
      .buildMailService(
        account,
        passwordOverride: _effectivePassword,
        oauthOverride: _pendingToken,
      );

  /// 是否已有可用的 OAuth 令牌（本次刚授权，或钥匙串里已存）。
  bool get _hasOAuthToken =>
      _pendingToken != null ||
      parseOauthToken(
            ref.watch(secretsProvider).mailOauth[widget.existing?.id],
          ) !=
          null;

  /// 走浏览器完成 Microsoft OAuth2 授权（授权码 + PKCE，本机回环接收）。
  Future<void> _authorize() async {
    final l10n = context.l10n;
    final clientId = _oauthClientId.text.trim();
    if (clientId.isEmpty) {
      // SnackBar 在对话框打开时会被遮罩压暗，改为对话框内红字。
      setState(() {
        _testResult = l10n.spacesOauthNeedClientId;
        _testResultKind = _TestResultKind.error;
      });
      return;
    }
    setState(() => _authorizing = true);
    try {
      final token = await MicrosoftOAuth.authorize(
        clientId: clientId,
        emailHint: _email.text.trim(),
      );
      if (!mounted) return;
      final expiry = formatDateTimeShort(context, token.expiresDateTime.toLocal());
      setState(() {
        _authorizing = false;
        _pendingToken = token;
        _testResult = l10n.spacesOauthSuccess(expiry);
        _testResultKind = _TestResultKind.ok;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authorizing = false;
        _testResult = l10n.spacesOauthFailed(e.toString());
        _testResultKind = _TestResultKind.error;
      });
    }
  }

  /// 保存后异步核对学习文件夹名：LIST 服务器文件夹，用 matchMailboxName
  /// 校验；连不上则跳过（「测试连接」里也会核对）。只提示、不阻塞。
  /// [svc] 与凭证必须在对话框关闭前构造好（销毁后不能再读 ref/controller）；
  /// [l10n] 同理，关闭后取不到 context。
  Future<void> _validateFolders(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    MailAccountConfig account,
    MailService svc,
  ) async {
    if (!svc.isReceiveReady) return;
    try {
      final serverFolders = await svc.listFolders();
      final missing = [
        for (final f in account.learnFolders)
          if (matchMailboxName(serverFolders, f) == null) f,
      ];
      if (missing.isEmpty) return;
      final sep = l10n.commonJoinSeparator;
      final preview =
          '${serverFolders.take(8).join(sep)}${serverFolders.length > 8 ? l10n.spacesFoldersMore(serverFolders.length) : ''}';
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.spacesFoldersMissing(
            account.email,
            missing.join(sep),
            preview,
          )),
        ),
      );
    } catch (_) {
      // 连不上服务器则跳过核对。
    }
  }

  Future<void> _test() async {
    final l10n = context.l10n;
    setState(() => _testing = true);
    final account = _buildFromForm();
    final svc = _mailServiceFor(account);
    var result = await svc.testConnection();
    final testOk = result == null;
    var resultKind = testOk ? _TestResultKind.ok : _TestResultKind.error;
    if (result == null) {
      // 连接成功，顺带核对学习文件夹名（一次额外连接，手动触发可接受）。
      try {
        final serverFolders = await svc.listFolders();
        final missing = [
          for (final f in account.learnFolders)
            if (matchMailboxName(serverFolders, f) == null) f,
        ];
        if (missing.isEmpty) {
          result = L10nMsg('spacesTestOkFoldersMatched',
              [account.learnFolders.join(l10n.commonJoinSeparator)]);
        } else {
          result = L10nMsg('spacesTestFoldersMissing',
              [missing.join(l10n.commonJoinSeparator)]);
          resultKind = _TestResultKind.warn;
        }
      } catch (_) {
        result = const L10nMsg('spacesTestOkImap');
      }
    }
    if (mounted) {
      setState(() {
        _testing = false;
        _lastTestOk = testOk;
        _testResult = result == null ? null : resolveL10nMsg(l10n, result);
        _testResultKind = resultKind;
      });
    }
  }

  /// 从服务器读取当前编辑账号的文件夹列表，勾选回填学习文件夹；
  /// 带 `\Sent` 特殊标记的文件夹标注「服务器已发送」。
  Future<void> _pickFoldersFromServer() async {
    final l10n = context.l10n;
    final account = _buildFromForm();
    final svc = _mailServiceFor(account);
    if (!svc.isReceiveReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _useOAuth
                ? l10n.spacesPickFoldersNeedOauth
                : l10n.spacesPickFoldersNeedCreds,
          ),
        ),
      );
      return;
    }
    try {
      final (folders, recommended) = await svc.listFoldersWithSentFlag();
      if (!mounted) return;
      final selected = _parseFolders().toSet();
      await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(l10n.spacesPickFoldersTitle),
            content: SizedBox(
              width: 400,
              height: 380,
              child: ListView(
                children: [
                  for (final f in folders)
                    CheckboxListTile(
                      value: selected.contains(f),
                      onChanged: (v) => setDialogState(
                        () => v == true ? selected.add(f) : selected.remove(f),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(f, overflow: TextOverflow.ellipsis),
                          ),
                          if (f == recommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.spacesServerSentBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.commonDone),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _learnFolders.text = selected.join(', ');
        _foldersTouched = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.spacesLoadFoldersFailed(e.toString()))));
      }
    }
  }

  /// 密码框提示：反映钥匙串里是否已存该账号的密码（密码本体不回填）。
  String _passwordHelper(AppLocalizations l10n) {
    final m = widget.existing;
    if (m == null) {
      return l10n.spacesPwdHelperNew;
    }
    final saved = ref.watch(secretsProvider).mailPasswords[m.id] ?? '';
    return saved.isNotEmpty
        ? l10n.spacesPwdHelperSaved
        : l10n.spacesPwdHelperNone;
  }

  /// OAuth2 模式的凭证区：Azure 客户端 ID + 浏览器授权按钮 + 授权状态。
  List<Widget> _oauthPane(AppLocalizations l10n) => [
    _field(
      _oauthClientId,
      l10n.spacesOauthClientIdLabel,
      helper: l10n.spacesOauthClientIdHelper,
    ),
    const SizedBox(height: 4),
    OutlinedButton.icon(
      onPressed: _authorizing ? null : _authorize,
      icon: _authorizing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.login),
      label: Text(
        _authorizing
            ? l10n.spacesOauthWaiting
            : (_hasOAuthToken
                ? l10n.spacesOauthRelogin
                : l10n.spacesOauthLogin),
      ),
    ),
    if (!_hasOAuthToken && !_authorizing)
      Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(
          l10n.spacesOauthNotYetHint,
          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? l10n.spacesAddAccountTitle(widget.space.name)
            : l10n.spacesEditAccountTitle(widget.existing!.email),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                _email,
                l10n.spacesFieldEmail,
                helper: l10n.spacesFieldEmailHelper,
              ),
              _field(_displayName, l10n.spacesFieldDisplayName),
              SwitchListTile(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: Text(l10n.spacesEnableAccount),
                subtitle: Text(l10n.spacesEnableAccountSubtitle),
                dense: true,
              ),
              SwitchListTile(
                value: _useOAuth,
                onChanged: (v) => setState(() {
                  _useOAuth = v;
                  _authTouched = true;
                }),
                title: Text(l10n.spacesOauthToggle),
                dense: true,
              ),
              if (_useOAuth)
                ..._oauthPane(l10n)
              else
                _field(
                  _password,
                  l10n.spacesFieldPassword,
                  obscure: true,
                  helper: _passwordHelper(l10n),
                ),
              // 收信 / 发信配置按 tab 分组。不用 TabBarView：它需要有界
              // 高度，而两个 tab 内容高度差异大（收信 tab 多出学习文件夹），
              // 固定高度会让发信 tab 大量留白，故按索引切换内容、用
              // AnimatedSize 平滑过渡高度。
              DefaultTabController(
                length: 2,
                child: TabBar(
                  tabs: [
                    Tab(text: l10n.spacesTabReceive),
                    Tab(text: l10n.spacesTabSend),
                  ],
                  onTap: (index) => setState(() => _tabIndex = index),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child: _tabIndex == 0 ? _receivePane() : _sendPane(),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_testing ? l10n.commonTesting : l10n.commonTestConnection),
              ),
              if (_testResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: switch (_testResultKind) {
                        _TestResultKind.warn => Colors.orange.shade800,
                        _TestResultKind.ok => Colors.green,
                        _ => Colors.red,
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.spacesSaveAccount)),
      ],
    );
  }

  Widget _receivePane() {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _receiveEnabled,
          onChanged: (v) => setState(() => _receiveEnabled = v),
          title: Text(l10n.spacesReceiveToggle),
          dense: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                _imapHost,
                l10n.spacesFieldImapHost,
                onChanged: (_) => _hostsTouched = true,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: _field(
                _imapPort,
                l10n.spacesFieldPort,
                num: true,
                onChanged: (_) => _hostsTouched = true,
              ),
            ),
          ],
        ),
        SwitchListTile(
          value: _imapSecure,
          onChanged: (v) => setState(() {
            _imapSecure = v;
            _hostsTouched = true;
          }),
          title: Text(l10n.spacesImapSslToggle),
          dense: true,
        ),
        const SizedBox(height: 12),
        _field(
          _learnFolders,
          l10n.spacesFieldLearnFolders,
          helper: l10n.spacesLearnFoldersHelper,
          onChanged: (_) => _foldersTouched = true,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.spacesLoadFoldersButton),
            onPressed: _pickFoldersFromServer,
          ),
        ),
      ],
    );
  }

  Widget _sendPane() {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _sendEnabled,
          onChanged: (v) => setState(() => _sendEnabled = v),
          title: Text(l10n.spacesSendToggle),
          dense: true,
        ),
        Row(
          children: [
            Expanded(
              child: _field(
                _smtpHost,
                l10n.spacesFieldSmtpHost,
                onChanged: (_) => _hostsTouched = true,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: _field(
                _smtpPort,
                l10n.spacesFieldPort,
                num: true,
                onChanged: (_) => _hostsTouched = true,
              ),
            ),
          ],
        ),
        SwitchListTile(
          value: _smtpSecure,
          onChanged: (v) => setState(() {
            _smtpSecure = v;
            _hostsTouched = true;
          }),
          title: Text(l10n.spacesSmtpSecureToggle),
          dense: true,
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool obscure = false,
    bool num = false,
    String? helper,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: num ? TextInputType.number : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}
