import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../../models/rule.dart';
import '../../providers/app_providers.dart';
import '../../services/llm_client.dart';
import '../../services/mail_service.dart';
import '../../services/paths.dart';
import '../../services/rule_generators.dart';
import '../../services/rule_store.dart' show newRuleFromGeneration;

/// 设置页：邮箱账号 / 大模型 / 学习范围 / 输出语言 / 自定义 Prompt。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _email;
  late final TextEditingController _displayName;
  late final TextEditingController _imapHost;
  late final TextEditingController _imapPort;
  late final TextEditingController _smtpHost;
  late final TextEditingController _smtpPort;
  late final TextEditingController _mailPassword;

  late final TextEditingController _llmBaseUrl;
  late final TextEditingController _llmModel;
  late final TextEditingController _llmApiKey;
  late final TextEditingController _temperature;
  late final TextEditingController _maxTokens;
  late final TextEditingController _timeout;

  late final TextEditingController _outputLanguage;
  late final TextEditingController _learnFolders;
  late final TextEditingController _learnMonths;
  late final TextEditingController _promptInput;

  bool _imapSecure = true;
  bool _smtpSecure = true;
  bool _initialized = false;
  String? _mailTestResult;
  String? _llmTestResult;
  bool _testing = false;

  @override
  void dispose() {
    for (final c in [
      _email, _displayName, _imapHost, _imapPort, _smtpHost, _smtpPort,
      _mailPassword, _llmBaseUrl, _llmModel, _llmApiKey, _temperature,
      _maxTokens, _timeout, _outputLanguage, _learnFolders, _learnMonths,
      _promptInput,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromState(ConfigState s) {
    if (_initialized) return;
    _initialized = true;
    final m = s.config.mail;
    final l = s.config.llm;
    _email.text = m.email;
    _displayName.text = m.displayName;
    _imapHost.text = m.imapHost;
    _imapPort.text = '${m.imapPort}';
    _smtpHost.text = m.smtpHost;
    _smtpPort.text = '${m.smtpPort}';
    _mailPassword.text = s.mailPassword ?? '';
    _imapSecure = m.imapSecure;
    _smtpSecure = m.smtpSecure;
    _llmBaseUrl.text = l.baseUrl;
    _llmModel.text = l.model;
    _llmApiKey.text = s.llmApiKey ?? '';
    _temperature.text = '${l.temperature}';
    _maxTokens.text = '${l.maxTokens}';
    _timeout.text = '${l.timeoutSeconds}';
    _outputLanguage.text = s.config.outputLanguage;
    _learnFolders.text = s.config.learnFolders.join(', ');
    _learnMonths.text = '${s.config.learnMonths}';
  }

  AppConfig _buildConfig(AppConfig current) => current.copyWith(
        mail: MailAccountConfig(
          email: _email.text.trim(),
          displayName: _displayName.text.trim(),
          imapHost: _imapHost.text.trim(),
          imapPort: int.tryParse(_imapPort.text.trim()) ?? 993,
          imapSecure: _imapSecure,
          smtpHost: _smtpHost.text.trim(),
          smtpPort: int.tryParse(_smtpPort.text.trim()) ?? 465,
          smtpSecure: _smtpSecure,
        ),
        llm: LlmConfig(
          baseUrl: _llmBaseUrl.text.trim(),
          model: _llmModel.text.trim(),
          temperature: double.tryParse(_temperature.text.trim()) ?? 0.3,
          maxTokens: int.tryParse(_maxTokens.text.trim()) ?? 2048,
          timeoutSeconds: int.tryParse(_timeout.text.trim()) ?? 120,
        ),
        outputLanguage:
            _outputLanguage.text.trim().isEmpty ? 'English' : _outputLanguage.text.trim(),
        learnFolders: _learnFolders.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        learnMonths: int.tryParse(_learnMonths.text.trim()) ?? 12,
      );

  Future<void> _save() async {
    await ref.read(configProvider.notifier).update(
          _buildConfig(ref.read(configProvider).config),
          mailPassword: _mailPassword.text,
          llmApiKey: _llmApiKey.text,
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('设置已保存')));
    }
  }

  Future<void> _testMail() async {
    setState(() => _testing = true);
    final config = _buildConfig(ref.read(configProvider).config);
    final mail = MailService(config.mail, _mailPassword.text);
    final error = await mail.testConnection();
    setState(() {
      _testing = false;
      _mailTestResult = error ?? '连接成功（IMAP 登录并读取文件夹正常）';
    });
  }

  Future<void> _testLlm() async {
    setState(() => _testing = true);
    final config = _buildConfig(ref.read(configProvider).config);
    final client = LlmClient(config: config.llm, apiKey: _llmApiKey.text);
    final error = await client.testConnection();
    setState(() {
      _testing = false;
      if (error == null) {
        final used = client.probedEndpoint ?? client.endpoint;
        _llmTestResult = '连接成功（$used）';
      } else {
        _llmTestResult = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(configProvider);
    _initFromState(s);
    final rulesCount = ref.watch(rulesProvider).enabled.length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('设置', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '当前启用规则 $rulesCount 条 · 数据目录 ${AppPaths.instance.root}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // ---------------- 邮箱账号 ----------------
        _section(
          title: '邮箱账号（IMAP 收件 / SMTP 发件）',
          children: [
            _textField(_email, '邮箱地址（同时作为登录用户名）'),
            _textField(_displayName, '发件显示名（可选）'),
            Row(children: [
              Expanded(child: _textField(_imapHost, 'IMAP 服务器，如 imap.qq.com')),
              const SizedBox(width: 12),
              SizedBox(width: 120, child: _textField(_imapPort, '端口', num: true)),
            ]),
            SwitchListTile(
              value: _imapSecure,
              onChanged: (v) => setState(() => _imapSecure = v),
              title: const Text('IMAP 使用 SSL（993 端口通常开启）'),
              dense: true,
            ),
            Row(children: [
              Expanded(child: _textField(_smtpHost, 'SMTP 服务器，如 smtp.qq.com')),
              const SizedBox(width: 12),
              SizedBox(width: 120, child: _textField(_smtpPort, '端口', num: true)),
            ]),
            SwitchListTile(
              value: _smtpSecure,
              onChanged: (v) => setState(() => _smtpSecure = v),
              title: const Text('SMTP 加密（465=SSL / 587=STARTTLS）'),
              dense: true,
            ),
            _textField(_mailPassword, '密码 / 授权码（QQ、163 等需用授权码）',
                obscure: true),
            _testRow(
                testing: _testing,
                result: _mailTestResult,
                label: '测试邮箱连接',
                onPressed: _testMail),
          ],
        ),

        // ---------------- 大模型 ----------------
        _section(
          title: '大模型（OpenAI 兼容接口）',
          children: [
            _textField(_llmBaseUrl, 'API 地址（通常以 /v1 结尾），如 https://api.deepseek.com/v1'),
            _textField(_llmModel, '模型名称，如 deepseek-chat'),
            _textField(_llmApiKey, 'API Key', obscure: true),
            Row(children: [
              Expanded(child: _textField(_temperature, '温度', num: true)),
              const SizedBox(width: 12),
              Expanded(child: _textField(_maxTokens, '最大 tokens', num: true)),
              const SizedBox(width: 12),
              Expanded(child: _textField(_timeout, '超时（秒）', num: true)),
            ]),
            _testRow(
                testing: _testing,
                result: _llmTestResult,
                label: '测试模型连接',
                onPressed: _testLlm),
          ],
        ),

        // ---------------- 学习与起草偏好 ----------------
        _section(
          title: '学习与起草偏好',
          children: [
            _textField(_outputLanguage, '草稿输出语言（默认 English）'),
            _textField(_learnFolders, '历史学习文件夹（逗号分隔，默认 Sent；可点下方按钮选择）'),
            _textField(_learnMonths, '学习时间范围（近 N 个月）', num: true),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('从服务器读取文件夹列表'),
                onPressed: () => _pickFolders(s),
              ),
            ),
          ],
        ),

        // ---------------- 自定义 Prompt ----------------
        _section(
          title: '自定义 Prompt 规则',
          subtitle: '把你对回复的要求沉淀成规则（会与历史邮件、知识库规则一起作为草稿依据）',
          children: [
            TextField(
              controller: _promptInput,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '例如：所有退款邮件先致歉再给方案；落款用 Best regards, Amy',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('经大模型拆分成规则（推荐）'),
                onPressed: () => _addPromptRule(useLlm: true),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('直接作为一条规则'),
                onPressed: () => _addPromptRule(useLlm: false),
              ),
            ]),
            const SizedBox(height: 8),
            Consumer(builder: (context, ref, _) {
              final promptsRules = ref
                  .watch(rulesProvider)
                  .rules
                  .where((r) => r.source.type == RuleSourceType.userPrompt)
                  .toList();
              if (promptsRules.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('暂无自定义 Prompt 规则', style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: [
                  for (final r in promptsRules)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.format_quote),
                      title: Text(r.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            ref.read(rulesProvider.notifier).delete(r.id),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),

        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('保存全部设置'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _pickFolders(ConfigState s) async {
    final mail = MailService(_buildConfig(s.config).mail, _mailPassword.text);
    try {
      final folders = await mail.listFolders();
      if (!mounted) return;
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
                    onTap: () {
                      final current = _learnFolders.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toSet();
                      if (current.contains(f)) {
                        current.remove(f);
                      } else {
                        current.add(f);
                      }
                      setState(() => _learnFolders.text = current.join(', '));
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

  Future<void> _addPromptRule({required bool useLlm}) async {
    final text = _promptInput.text.trim();
    if (text.isEmpty) return;
    final llm = ref.read(llmClientProvider);

    if (useLlm) {
      if (llm == null) {
        _toast('请先保存大模型配置');
        return;
      }
      _toast('正在拆分规则…');
      try {
        final generator = RuleGenerators(
            llm: llm, store: ref.read(rulesProvider.notifier).store);
        final drafts = await generator.draftFromUserPrompt(text);
        if (!mounted || drafts.isEmpty) return;
        final checks = List<bool>.filled(drafts.length, true);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认生成的规则'),
            content: SizedBox(
              width: 440,
              child: StatefulBuilder(
                builder: (context, setDialogState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < drafts.length; i++)
                      CheckboxListTile(
                        value: checks[i],
                        onChanged: (v) =>
                            setDialogState(() => checks[i] = v ?? false),
                        title: Text(drafts[i].$2),
                        subtitle: Text(drafts[i].$1.label),
                        dense: true,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('添加选中项'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        var added = 0;
        for (var i = 0; i < drafts.length; i++) {
          if (!checks[i]) continue;
          await ref.read(rulesProvider.notifier).store.add(
                newRuleFromGeneration(
                  type: RuleSourceType.userPrompt,
                  generatedBy: llm.generatedBy,
                  details: {'prompt_text': text},
                  content: drafts[i].$2,
                  category: drafts[i].$1,
                ),
              );
          added++;
        }
        await ref.read(rulesProvider.notifier).reload();
        if (added > 0) {
          _promptInput.clear();
          _toast('已添加 $added 条规则');
        }
      } catch (e) {
        _toast('拆分失败：$e');
      }
    } else {
      await ref.read(rulesProvider.notifier).store.add(
            newRuleFromGeneration(
              type: RuleSourceType.userPrompt,
              generatedBy: '',
              details: {'prompt_text': text},
              content: text,
              category: RuleCategory.other,
            ),
          );
      await ref.read(rulesProvider.notifier).reload();
      _toast('已添加规则');
      _promptInput.clear();
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _section({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _textField(TextEditingController c, String label,
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

  Widget _testRow({
    required bool testing,
    required String? result,
    required String label,
    required Future<void> Function() onPressed,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: testing ? null : onPressed,
            icon: testing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_tethering),
            label: Text(label),
          ),
          if (result != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                result,
                style: TextStyle(
                  color: result.contains('成功') ? Colors.green : Colors.red,
                ),
              ),
            ),
        ],
      );
}
