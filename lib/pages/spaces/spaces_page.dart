import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          Text('空间管理', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            '一个空间是一个独立的业务上下文（如一个店铺 / 品牌）：\n'
            '· 空间内共用一套回复规则与知识库\n'
            '· 可配置多个邮箱账号，分别设置收信（IMAP）与发信（SMTP）能力\n'
            '· 转发来的邮件（如客户发给 support@，转发到配置账号）会自动识别原始收件地址，回信时抄送',
            style: TextStyle(height: 1.7),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createSpace(),
            icon: const Icon(Icons.add),
            label: const Text('新建第一个空间'),
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
              Text('空间管理', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 12),
              Text(
                '共 ${spaces.length} 个空间',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _createSpace,
                icon: const Icon(Icons.add),
                label: const Text('新建空间'),
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
                                  '当前',
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
                          '${s.accounts.length} 个账号 · '
                          '${s.receiveAccounts.length} 收 / ${s.sendAccounts.length} 发',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: '删除空间',
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
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建空间'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '空间名称（如店铺 / 品牌名）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除空间「${space.name}」'),
        content: const Text(
          '将删除该空间的规则库、知识库、学习状态与草稿记录，以及全部账号的已存密码。\n'
          '此操作不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
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
                '空间：${space.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (cur.space?.id != space.id)
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(spaceSelectionProvider.notifier)
                    .switchTo(space.id),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('设为当前空间'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ---------------- 基本信息 ----------------
        _section(
          context,
          title: '基本信息',
          children: [
            _textField(_name, '空间名称'),
            _dropdown(
              value: _llmId,
              label: '分配大模型（在设置页管理多个模型）',
              items: [
                const DropdownMenuItem(value: '', child: Text('未分配')),
                for (final p in profiles)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name}（${p.config.model}）'),
                  ),
              ],
              onChanged: (v) => setState(() {
                _llmId = v ?? '';
                _persist(widget.space);
              }),
            ),
            _dropdown(
              value: _defaultSendId,
              label: '默认发信账号（收信账号未开发信时回落使用）',
              items: [
                const DropdownMenuItem(value: '', child: Text('自动（任一可发信账号）')),
                for (final a in space.sendAccounts)
                  DropdownMenuItem(value: a.id, child: Text(a.email)),
              ],
              onChanged: (v) => setState(() {
                _defaultSendId = v ?? '';
                _persist(widget.space);
              }),
            ),
            _textField(_outputLanguage, '草稿输出语言（默认 English）'),
          ],
        ),

        // ---------------- 学习偏好 ----------------
        _section(
          context,
          title: '学习偏好（按空间）',
          children: [
            _textField(_learnMonths, '学习时间范围（近 N 个月）', num: true),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                '历史学习文件夹按邮箱账号单独设置（文件夹名因服务商而异：Gmail 为 '
                '[Gmail]/Sent Mail（中文账号为 [Gmail]/已发送邮件）、QQ/163 为 '
                'Sent Messages、Outlook 为 Sent）。请在下方「邮箱账号」中编辑各账号'
                '填写；常见命名会自动匹配，全部未命中时学习会按服务器标记自动识别。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),

        // ---------------- 账号管理 ----------------
        _section(
          context,
          title: '邮箱账号（${space.accounts.length}）',
          subtitle: '每个账号可分别设置收信（IMAP）与发信（SMTP）能力；回信默认用收信账号发出',
          children: [
            if (space.accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '还没有账号，点击下方按钮添加',
                  style: TextStyle(color: Colors.grey),
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
              label: const Text('添加邮箱账号'),
            ),
          ],
        ),

        const SizedBox(height: 8),
        const Center(
          child: Text(
            '修改后自动保存',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除账号 ${account.email}'),
        content: const Text('将移除该账号的配置与已存密码。空间内数据不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
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
            if (!account.enabled) _badge(context, '已停用', Colors.grey),
            _badge(
              context,
              account.receiveEnabled ? '收信' : '不收信',
              account.receiveEnabled ? Colors.green : Colors.grey,
            ),
            _badge(
              context,
              account.sendEnabled ? '发信' : '不发信',
              account.sendEnabled ? Colors.blue : Colors.grey,
            ),
            if (isDefaultSender) _badge(context, '默认发信', Colors.deepOrange),
            _badge(
              context,
              '学习 ${account.learnFolders.join('、')}',
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
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: '删除',
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
  String? _forcedOffReason() {
    if (_useOAuth) {
      if (!_hasOAuthToken) return '尚未完成 Microsoft 授权';
    } else if (_effectivePassword == null && !_hadStoredPassword) {
      return '尚未填写密码 / 授权码';
    }
    if (_lastTestOk == false) return '最近一次「测试连接」未成功';
    return null;
  }

  Future<void> _save() async {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写邮箱地址')));
      return;
    }
    // 不强制连接成功：未就绪的账号照常保存，只是自动停用，可稍后补齐再启用。
    final offReason = _forcedOffReason();
    var account = _buildFromForm();
    if (offReason != null) account = account.copyWith(enabled: false);
    final password = _effectivePassword;
    // 对话框即将关闭：先取根级 messenger 与测试用凭证，保存后再异步核对。
    final messenger = ScaffoldMessenger.of(context);
    final svc = _mailServiceFor(account);
    Navigator.pop(context);
    if (offReason != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${account.email}：$offReason，已保存为停用状态，'
            '补齐并验证后可在账号列表中开启',
          ),
        ),
      );
    }
    await widget.onSaved(account, password, _pendingToken);
    unawaited(_validateFolders(messenger, account, svc));
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
    final clientId = _oauthClientId.text.trim();
    if (clientId.isEmpty) {
      // SnackBar 在对话框打开时会被遮罩压暗，改为对话框内红字。
      setState(() => _testResult = '请先填写 Azure 应用客户端 ID'
          '（Azure 应用 Overview 页的 Application (client) ID）');
      return;
    }
    setState(() => _authorizing = true);
    try {
      final token = await MicrosoftOAuth.authorize(
        clientId: clientId,
        emailHint: _email.text.trim(),
      );
      if (!mounted) return;
      final expiry = token.expiresDateTime.toLocal().toString().substring(
        0,
        16,
      );
      setState(() {
        _authorizing = false;
        _pendingToken = token;
        _testResult = '✓ Microsoft 授权成功（令牌有效期至 $expiry，到期自动续期）';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authorizing = false;
        _testResult = '授权失败：$e';
      });
    }
  }

  /// 保存后异步核对学习文件夹名：LIST 服务器文件夹，用 matchMailboxName
  /// 校验；连不上则跳过（「测试连接」里也会核对）。只提示、不阻塞。
  /// [svc] 与凭证必须在对话框关闭前构造好（销毁后不能再读 ref/controller）。
  Future<void> _validateFolders(
    ScaffoldMessengerState messenger,
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
      final preview = serverFolders.take(8).join('、');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${account.email}：学习文件夹「${missing.join('、')}」在服务器上不存在'
            '（现有：$preview'
            '${serverFolders.length > 8 ? ' 等共 ${serverFolders.length} 个' : ''}），'
            '可编辑该账号并点「从服务器读取文件夹列表」选取',
          ),
        ),
      );
    } catch (_) {
      // 连不上服务器则跳过核对。
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final account = _buildFromForm();
    final svc = _mailServiceFor(account);
    var result = await svc.testConnection();
    final testOk = result == null;
    if (result == null) {
      // 连接成功，顺带核对学习文件夹名（一次额外连接，手动触发可接受）。
      try {
        final serverFolders = await svc.listFolders();
        final missing = [
          for (final f in account.learnFolders)
            if (matchMailboxName(serverFolders, f) == null) f,
        ];
        result = missing.isEmpty
            ? '连接成功；学习文件夹「${account.learnFolders.join('、')}」✓ 已匹配'
            : '连接成功；⚠ 学习文件夹「${missing.join('、')}」在服务器上不存在'
                  '（可点下方按钮从服务器选取）';
      } catch (_) {
        result = '连接成功（IMAP 登录正常）';
      }
    }
    if (mounted) {
      setState(() {
        _testing = false;
        _lastTestOk = testOk;
        _testResult = result;
      });
    }
  }

  /// 从服务器读取当前编辑账号的文件夹列表，勾选回填学习文件夹；
  /// 带 `\Sent` 特殊标记的文件夹标注「服务器已发送」。
  Future<void> _pickFoldersFromServer() async {
    final account = _buildFromForm();
    final svc = _mailServiceFor(account);
    if (!svc.isReceiveReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _useOAuth ? '请先填写邮箱地址并完成 Microsoft 授权' : '请先填写邮箱地址、IMAP 服务器和密码',
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
            title: const Text('选择历史学习文件夹'),
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
                              child: const Text(
                                '服务器已发送',
                                style: TextStyle(
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
                child: const Text('完成'),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('读取文件夹失败：$e')));
      }
    }
  }

  /// 密码框提示：反映钥匙串里是否已存该账号的密码（密码本体不回填）。
  String get _passwordHelper {
    final m = widget.existing;
    if (m == null) {
      return 'QQ、163 等需在邮箱后台生成授权码；保存后加密存入系统钥匙串';
    }
    final saved = ref.watch(secretsProvider).mailPasswords[m.id] ?? '';
    return saved.isNotEmpty ? '已保存授权码（框内圆点仅为占位）；更换时直接输入新授权码' : '尚未保存密码';
  }

  /// OAuth2 模式的凭证区：Azure 客户端 ID + 浏览器授权按钮 + 授权状态。
  List<Widget> _oauthPane() => [
    _field(
      _oauthClientId,
      'Azure 应用客户端 ID',
      helper:
          'Azure 门户注册「移动和桌面应用」获得（重定向 URI 填 '
          'http://localhost，账号类型含个人 Microsoft 帐户）；'
          '多个 Outlook 账号可复用同一个 ID',
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
            ? '等待浏览器完成授权…（最多 5 分钟）'
            : (_hasOAuthToken ? '重新登录 Microsoft 账号' : '登录 Microsoft 账号'),
      ),
    ),
    if (!_hasOAuthToken && !_authorizing)
      Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(
          '尚未授权：也可先保存（账号将处于停用状态），稍后编辑完成登录再启用'
          '（Outlook 还需先在网页版设置里开启 IMAP）',
          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? '添加邮箱账号（空间：${widget.space.name}）'
            : '编辑账号 ${widget.existing!.email}',
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
                '邮箱地址（同时作为登录用户名）',
                helper:
                    '常见邮箱（Gmail / QQ / 163 / Outlook 等）'
                    '输入地址后自动填充下方服务器与学习文件夹',
              ),
              _field(_displayName, '发件显示名（可选）'),
              SwitchListTile(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: const Text('启用此账号'),
                subtitle: const Text('停用后不参与收信、发信与学习，配置保留可随时再开启'),
                dense: true,
              ),
              SwitchListTile(
                value: _useOAuth,
                onChanged: (v) => setState(() {
                  _useOAuth = v;
                  _authTouched = true;
                }),
                title: const Text('OAuth2 登录（Outlook 必需：微软已禁用密码登录）'),
                dense: true,
              ),
              if (_useOAuth)
                ..._oauthPane()
              else
                _field(
                  _password,
                  '密码 / 授权码',
                  obscure: true,
                  helper: _passwordHelper,
                ),
              // 收信 / 发信配置按 tab 分组。不用 TabBarView：它需要有界
              // 高度，而两个 tab 内容高度差异大（收信 tab 多出学习文件夹），
              // 固定高度会让发信 tab 大量留白，故按索引切换内容、用
              // AnimatedSize 平滑过渡高度。
              DefaultTabController(
                length: 2,
                child: TabBar(
                  tabs: const [
                    Tab(text: '收信（IMAP）'),
                    Tab(text: '发信（SMTP）'),
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
                label: Text(_testing ? '测试中…' : '测试连接'),
              ),
              if (_testResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testResult!.contains('⚠')
                          ? Colors.orange.shade800
                          : (_testResult!.contains('成功')
                                ? Colors.green
                                : Colors.red),
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
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存账号')),
      ],
    );
  }

  Widget _receivePane() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile(
        value: _receiveEnabled,
        onChanged: (v) => setState(() => _receiveEnabled = v),
        title: const Text('收信（IMAP：拉取收件箱、参与学习）'),
        dense: true,
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _field(
              _imapHost,
              'IMAP 服务器，如 imap.qq.com',
              onChanged: (_) => _hostsTouched = true,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: _field(
              _imapPort,
              '端口',
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
        title: const Text('IMAP 使用 SSL（993 端口通常开启）'),
        dense: true,
      ),
      SizedBox(height: 12),
      _field(
        _learnFolders,
        '历史学习文件夹（逗号分隔，默认 Sent）',
        helper:
            '文件夹名因邮箱服务商而异：Gmail 为 [Gmail]/Sent Mail'
            '（中文账号为 [Gmail]/已发送邮件）、QQ/163 为 Sent Messages、'
            'Outlook 为 Sent。常见命名会自动匹配，不确定可点下方按钮'
            '从服务器选取',
        onChanged: (_) => _foldersTouched = true,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('从服务器读取文件夹列表'),
          onPressed: _pickFoldersFromServer,
        ),
      ),
    ],
  );

  Widget _sendPane() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile(
        value: _sendEnabled,
        onChanged: (v) => setState(() => _sendEnabled = v),
        title: const Text('发信（SMTP：可用于发出回复）'),
        dense: true,
      ),
      Row(
        children: [
          Expanded(
            child: _field(
              _smtpHost,
              'SMTP 服务器，如 smtp.qq.com（只收信可留空）',
              onChanged: (_) => _hostsTouched = true,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: _field(
              _smtpPort,
              '端口',
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
        title: const Text('SMTP 加密（465=SSL / 587=STARTTLS）'),
        dense: true,
      ),
    ],
  );

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
