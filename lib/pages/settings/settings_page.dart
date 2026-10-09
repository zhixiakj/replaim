import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../../models/llm_profile.dart';
import '../../models/rule.dart';
import '../../providers/app_providers.dart';
import '../../services/llm_client.dart';
import '../../services/paths.dart';
import '../../services/rule_generators.dart';
import '../../services/rule_store.dart' show newRuleFromGeneration;

/// 设置页：全局 LLM Profiles（可配置多个，分配给各空间）+ 自定义 Prompt 规则。
/// 邮箱账号与学习偏好按空间管理，见「空间」页。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _promptInput = TextEditingController();

  @override
  void dispose() {
    _promptInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(llmProfilesProvider).profiles;
    final rulesCount = ref.watch(rulesProvider).enabled.length;
    final assigned =
        ref.watch(spacesProvider).spaces.where((s) => s.llmProfileId != null).length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('设置', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '当前空间启用规则 $rulesCount 条 · 数据目录 ${AppPaths.instance.root}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // ---------------- 大模型 ----------------
        _section(
          title: '大模型（全局，OpenAI 兼容接口）',
          subtitle: '可配置多个模型端点，在「空间」页分配给各空间使用；'
              '当前 $assigned 个空间已分配模型',
          children: [
            if (profiles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('还没有模型配置，点击下方按钮添加',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              for (final p in profiles)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: Text('${p.name}（${p.config.model}）'),
                  subtitle: Text(p.config.baseUrl,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '编辑',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editProfile(p),
                      ),
                      IconButton(
                        tooltip: '删除',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteProfile(p),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _editProfile(null),
              icon: const Icon(Icons.add),
              label: const Text('添加大模型'),
            ),
          ],
        ),

        // ---------------- 自定义 Prompt ----------------
        _section(
          title: '自定义 Prompt 规则',
          subtitle: '把你对回复的要求沉淀成规则（写入当前空间，与历史邮件、知识库规则一起作为草稿依据）',
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
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _editProfile(LlmProfile? existing) async {
    final isEdit = existing != null;
    final name = TextEditingController(text: existing?.name ?? '');
    final baseUrl = TextEditingController(text: existing?.config.baseUrl ?? '');
    final model = TextEditingController(text: existing?.config.model ?? '');
    final apiKey = TextEditingController();
    final temperature =
        TextEditingController(text: '${existing?.config.temperature ?? 0.3}');
    final maxTokens =
        TextEditingController(text: '${existing?.config.maxTokens ?? 2048}');
    final timeout =
        TextEditingController(text: '${existing?.config.timeoutSeconds ?? 120}');
    var testing = false;
    String? testResult;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑大模型' : '添加大模型'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(name, '名称（如 DeepSeek、公司 GPT）'),
                  _field(baseUrl, 'API 地址（通常以 /v1 结尾），如 https://api.deepseek.com/v1'),
                  _field(model, '模型名称，如 deepseek-chat'),
                  _field(apiKey, 'API Key（编辑时留空保持不变）', obscure: true),
                  Row(children: [
                    Expanded(child: _field(temperature, '温度', num: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(maxTokens, '最大 tokens', num: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(timeout, '超时（秒）', num: true)),
                  ]),
                  OutlinedButton.icon(
                    onPressed: testing
                        ? null
                        : () async {
                            setDialogState(() => testing = true);
                            final config = LlmConfig(
                              baseUrl: baseUrl.text.trim(),
                              model: model.text.trim(),
                              temperature:
                                  double.tryParse(temperature.text.trim()) ?? 0.3,
                              maxTokens:
                                  int.tryParse(maxTokens.text.trim()) ?? 2048,
                              timeoutSeconds:
                                  int.tryParse(timeout.text.trim()) ?? 120,
                            );
                            final key = apiKey.text.isNotEmpty
                                ? apiKey.text
                                : ref
                                    .read(secretsProvider)
                                    .llmApiKeys[existing?.id];
                            final client =
                                LlmClient(config: config, apiKey: key);
                            final error = await client.testConnection();
                            setDialogState(() {
                              testing = false;
                              testResult = error ??
                                  '连接成功（${client.probedEndpoint ?? client.endpoint}）';
                            });
                          },
                    icon: testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering),
                    label: Text(testing ? '测试中…' : '测试连接'),
                  ),
                  if (testResult != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        testResult!,
                        style: TextStyle(
                          color: testResult!.contains('成功')
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final config = LlmConfig(
      baseUrl: baseUrl.text.trim(),
      model: model.text.trim(),
      temperature: double.tryParse(temperature.text.trim()) ?? 0.3,
      maxTokens: int.tryParse(maxTokens.text.trim()) ?? 2048,
      timeoutSeconds: int.tryParse(timeout.text.trim()) ?? 120,
    );
    if (existing != null) {
      existing
        ..name = name.text.trim().isEmpty ? existing.name : name.text.trim()
        ..config = config;
      await ref.read(llmProfilesProvider.notifier).save(
            existing,
            apiKey: apiKey.text.isNotEmpty ? apiKey.text : null,
          );
    } else {
      await ref.read(llmProfilesProvider.notifier).create(
            name.text.trim().isEmpty ? '未命名模型' : name.text.trim(),
            config: config,
            apiKey: apiKey.text,
          );
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已保存大模型配置')));
    }
  }

  Future<void> _deleteProfile(LlmProfile profile) async {
    final spacesUsing = ref
        .read(spacesProvider)
        .spaces
        .where((s) => s.llmProfileId == profile.id)
        .map((s) => s.name)
        .toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除大模型「${profile.name}」'),
        content: Text(spacesUsing.isEmpty
            ? '该模型未被任何空间使用。'
            : '以下空间正在使用该模型，删除后将变为未分配：\n${spacesUsing.join('、')}'),
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
    await ref.read(llmProfilesProvider.notifier).delete(profile.id);
  }

  Future<void> _addPromptRule({required bool useLlm}) async {
    final text = _promptInput.text.trim();
    if (text.isEmpty) return;
    final llm = ref.read(llmClientProvider);

    if (useLlm) {
      if (llm == null) {
        _toast(ref.read(llmUnavailableReasonProvider));
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
