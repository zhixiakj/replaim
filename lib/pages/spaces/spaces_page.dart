import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/mail_space.dart';
import '../../providers/app_providers.dart';
import '../../services/id_gen.dart';
import '../../services/mail_service.dart';

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
              Text('共 ${spaces.length} 个空间',
                  style: Theme.of(context).textTheme.bodySmall),
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
                                child: Text(s.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '当前',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                child: _SpaceDetail(
                  key: ValueKey(editing.id),
                  space: editing,
                ),
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
                backgroundColor: Theme.of(context).colorScheme.error),
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
  late final TextEditingController _learnFolders;
  late final TextEditingController _learnMonths;
  String _llmId = '';
  String _defaultSendId = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _outputLanguage = TextEditingController();
    _learnFolders = TextEditingController();
    _learnMonths = TextEditingController();
    _initFrom(widget.space);
  }

  void _initFrom(MailSpace s) {
    _name.text = s.name;
    _outputLanguage.text = s.outputLanguage;
    _learnFolders.text = s.learnFolders.join(', ');
    _learnMonths.text = '${s.learnMonths}';
    _llmId = s.llmProfileId ?? '';
    _defaultSendId = s.defaultSendAccountId ?? '';
  }

  @override
  void didUpdateWidget(covariant _SpaceDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换编辑对象时重新装载；同一空间的编辑保存不回填（保留未保存输入）。
    if (oldWidget.space.id != widget.space.id) {
      _initFrom(widget.space);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _outputLanguage.dispose();
    _learnFolders.dispose();
    _learnMonths.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final space = ref.read(spacesProvider).byId(widget.space.id);
    if (space == null) return;
    space
      ..name = _name.text.trim().isEmpty ? space.name : _name.text.trim()
      ..outputLanguage =
          _outputLanguage.text.trim().isEmpty ? 'English' : _outputLanguage.text.trim()
      ..learnMonths = int.tryParse(_learnMonths.text.trim()) ?? space.learnMonths
      ..llmProfileId = _llmId.isEmpty ? null : _llmId
      ..defaultSendAccountId = _defaultSendId.isEmpty ? null : _defaultSendId;
    final folders = _learnFolders.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    space.learnFolders
      ..clear()
      ..addAll(folders.isEmpty ? ['Sent'] : folders);
    await ref.read(spacesProvider.notifier).save(space);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('空间设置已保存')));
    }
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
              child: Text('空间：${space.name}',
                  style: Theme.of(context).textTheme.titleLarge),
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
        _section(context, title: '基本信息', children: [
          _textField(_name, '空间名称'),
          InputDecorator(
            decoration: const InputDecoration(
                labelText: '分配大模型（在设置页管理多个模型）',
                border: OutlineInputBorder(),
                isDense: true),
            child: DropdownButton<String>(
              value: _llmId,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: '', child: Text('未分配')),
                for (final p in profiles)
                  DropdownMenuItem(
                      value: p.id, child: Text('${p.name}（${p.config.model}）')),
              ],
              onChanged: (v) => setState(() => _llmId = v ?? ''),
            ),
          ),
          InputDecorator(
            decoration: const InputDecoration(
                labelText: '默认发信账号（收信账号未开发信时回落使用）',
                border: OutlineInputBorder(),
                isDense: true),
            child: DropdownButton<String>(
              value: _defaultSendId,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: '', child: Text('自动（任一可发信账号）')),
                for (final a in space.sendAccounts)
                  DropdownMenuItem(value: a.id, child: Text(a.email)),
              ],
              onChanged: (v) => setState(() => _defaultSendId = v ?? ''),
            ),
          ),
          _textField(_outputLanguage, '草稿输出语言（默认 English）'),
        ]),

        // ---------------- 学习偏好 ----------------
        _section(context, title: '学习偏好（按空间）', children: [
          _textField(_learnFolders, '历史学习文件夹（逗号分隔，默认 Sent）'),
          _textField(_learnMonths, '学习时间范围（近 N 个月）', num: true),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('从服务器读取文件夹列表'),
              onPressed: () => _pickFolders(space),
            ),
          ),
        ]),

        // ---------------- 账号管理 ----------------
        _section(
          context,
          title: '邮箱账号（${space.accounts.length}）',
          subtitle: '每个账号可分别设置收信（IMAP）与发信（SMTP）能力；回信默认用收信账号发出',
          children: [
            if (space.accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('还没有账号，点击下方按钮添加',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              for (var i = 0; i < space.accounts.length; i++)
                _AccountTile(
                  account: space.accounts[i],
                  isDefaultSender: space.defaultSendAccountId == space.accounts[i].id,
                  onEdit: () => _editAccount(space.accounts[i]),
                  onDelete: () => _deleteAccount(space.accounts[i]),
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
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('保存空间设置'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _pickFolders(MailSpace space) async {
    // 用第一个配置完整的收信账号读取文件夹列表。
    MailAccountConfig? account;
    String? password;
    for (final a in space.receiveAccounts) {
      final pwd = ref.read(secretsProvider).mailPasswords[a.id];
      if (MailService(a, pwd).isConfigured) {
        account = a;
        password = pwd;
        break;
      }
    }
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先添加一个配置完整的收信账号')));
      return;
    }
    try {
      final folders = await MailService(account, password).listFolders();
      if (!mounted) return;
      final current = _learnFolders.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择学习文件夹'),
          content: SizedBox(
            width: 380,
            height: 360,
            child: ListView(
              children: [
                for (final f in folders)
                  ListTile(
                    title: Text(f),
                    dense: true,
                    trailing: current.contains(f)
                        ? const Icon(Icons.check, size: 18)
                        : null,
                    onTap: () {
                      setState(() {
                        if (current.contains(f)) {
                          current.remove(f);
                        } else {
                          current.add(f);
                        }
                        _learnFolders.text = current.join(', ');
                      });
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('读取文件夹失败：$e')));
      }
    }
  }

  Future<void> _editAccount(MailAccountConfig? existing) async {
    final space = ref.read(spacesProvider).byId(widget.space.id);
    if (space == null) return;
    await showDialog(
      context: context,
      builder: (context) => _AccountDialog(
        space: space,
        existing: existing,
        onSaved: (account, password) async {
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
        },
      ),
    );
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

  Widget _section(BuildContext context,
      {required String title,
      String? subtitle,
      required List<Widget> children}) {
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

  Widget _textField(TextEditingController c, String label, {bool num = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: num ? TextInputType.number : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );
}

/// 账号卡片：邮箱 + 收/发能力徽标 + 编辑 / 删除。
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isDefaultSender,
    required this.onEdit,
    required this.onDelete,
  });

  final MailAccountConfig account;
  final bool isDefaultSender;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        account.receiveEnabled && account.sendEnabled
            ? Icons.mark_email_unread
            : (account.receiveEnabled ? Icons.move_to_inbox : Icons.outgoing_mail),
        size: 20,
        color: Theme.of(context).colorScheme.primary,
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
            _badge(context, account.receiveEnabled ? '收信' : '不收信',
                account.receiveEnabled ? Colors.green : Colors.grey),
            _badge(context, account.sendEnabled ? '发信' : '不发信',
                account.sendEnabled ? Colors.blue : Colors.grey),
            if (isDefaultSender) _badge(context, '默认发信', Colors.deepOrange),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        child: Text(text,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 1))),
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
  final Future<void> Function(MailAccountConfig account, String? password)
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

  bool _imapSecure = true;
  bool _smtpSecure = true;
  bool _receiveEnabled = true;
  bool _sendEnabled = true;
  bool _testing = false;
  String? _testResult;

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
    _imapSecure = m?.imapSecure ?? true;
    _smtpSecure = m?.smtpSecure ?? true;
    _receiveEnabled = m?.receiveEnabled ?? true;
    _sendEnabled = m?.sendEnabled ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _email, _displayName, _imapHost, _imapPort, _smtpHost, _smtpPort,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  MailAccountConfig _buildFromForm() => (widget.existing ??
          MailAccountConfig(id: newAccountId()))
      .copyWith(
    email: _email.text.trim(),
    displayName: _displayName.text.trim(),
    imapHost: _imapHost.text.trim(),
    imapPort: int.tryParse(_imapPort.text.trim()) ?? 993,
    imapSecure: _imapSecure,
    smtpHost: _smtpHost.text.trim(),
    smtpPort: int.tryParse(_smtpPort.text.trim()) ?? 465,
    smtpSecure: _smtpSecure,
    receiveEnabled: _receiveEnabled,
    sendEnabled: _sendEnabled,
  );

  Future<void> _save() async {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写邮箱地址')));
      return;
    }
    final account = _buildFromForm();
    Navigator.pop(context);
    await widget.onSaved(account, _password.text);
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final account = _buildFromForm();
    // 密码留空时用已存密码测试。
    final password = _password.text.isNotEmpty
        ? _password.text
        : ref.read(secretsProvider).mailPasswords[account.id];
    final error = await MailService(account, password).testConnection();
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = error ?? '连接成功（IMAP 登录并读取文件夹正常）';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? '添加邮箱账号（空间：${widget.space.name}）'
          : '编辑账号 ${widget.existing!.email}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_email, '邮箱地址（同时作为登录用户名）'),
              _field(_displayName, '发件显示名（可选）'),
              Row(children: [
                Expanded(child: _field(_imapHost, 'IMAP 服务器，如 imap.qq.com')),
                const SizedBox(width: 12),
                SizedBox(width: 120, child: _field(_imapPort, '端口', num: true)),
              ]),
              SwitchListTile(
                value: _imapSecure,
                onChanged: (v) => setState(() => _imapSecure = v),
                title: const Text('IMAP 使用 SSL（993 端口通常开启）'),
                dense: true,
              ),
              Row(children: [
                Expanded(child: _field(_smtpHost, 'SMTP 服务器，如 smtp.qq.com')),
                const SizedBox(width: 12),
                SizedBox(width: 120, child: _field(_smtpPort, '端口', num: true)),
              ]),
              SwitchListTile(
                value: _smtpSecure,
                onChanged: (v) => setState(() => _smtpSecure = v),
                title: const Text('SMTP 加密（465=SSL / 587=STARTTLS）'),
                dense: true,
              ),
              _field(_password,
                  '密码 / 授权码（QQ、163 等需用授权码；编辑时留空保持不变）',
                  obscure: true),
              SwitchListTile(
                value: _receiveEnabled,
                onChanged: (v) => setState(() => _receiveEnabled = v),
                title: const Text('收信（IMAP：拉取收件箱、参与学习）'),
                dense: true,
              ),
              SwitchListTile(
                value: _sendEnabled,
                onChanged: (v) => setState(() => _sendEnabled = v),
                title: const Text('发信（SMTP：可用于发出回复）'),
                dense: true,
              ),
              OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering),
                label: Text(_testing ? '测试中…' : '测试连接'),
              ),
              if (_testResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testResult!.contains('成功')
                          ? Colors.green
                          : Colors.red,
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
        FilledButton(
          onPressed: _save,
          child: const Text('保存账号'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
          {bool obscure = false, bool num = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: num ? TextInputType.number : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );
}
