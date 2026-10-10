import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../l10n/model_labels.dart';
import '../../l10n/resolve_msg.dart';
import '../../models/app_config.dart';
import '../../models/llm_profile.dart';
import '../../models/rule.dart';
import '../../providers/app_providers.dart';
import '../../providers/locale_provider.dart';
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
    final l10n = context.l10n;
    final profiles = ref.watch(llmProfilesProvider).profiles;
    final rulesCount = ref.watch(rulesProvider).enabled.length;
    final assigned =
        ref.watch(spacesProvider).spaces.where((s) => s.llmProfileId != null).length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.navSettings, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          l10n.settingsSummary(rulesCount, AppPaths.instance.root),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // ---------------- 通用 ----------------
        _section(
          title: l10n.settingsGeneralTitle,
          children: [
            Row(children: [
              Text(l10n.settingsLanguageLabel),
              const SizedBox(width: 16),
              Consumer(builder: (context, ref, _) {
                final locale = ref.watch(localeProvider);
                return DropdownButton<Locale?>(
                  value: locale,
                  items: [
                    DropdownMenuItem(
                        value: null, child: Text(l10n.settingsLanguageSystem)),
                    const DropdownMenuItem(
                        value: Locale('zh'), child: Text('简体中文')),
                    const DropdownMenuItem(
                        value: Locale('en'), child: Text('English')),
                  ],
                  onChanged: (v) =>
                      ref.read(localeProvider.notifier).setLocale(v),
                );
              }),
            ]),
          ],
        ),

        // ---------------- 大模型 ----------------
        _section(
          title: l10n.settingsLlmSectionTitle,
          subtitle: l10n.settingsLlmSectionSubtitle(assigned),
          children: [
            if (profiles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.settingsLlmEmpty,
                    style: const TextStyle(color: Colors.grey)),
              )
            else
              for (final p in profiles)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: Text(l10n.llmProfileTitle(p.name, p.config.model)),
                  subtitle: Text(p.config.baseUrl,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.commonEdit,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editProfile(p),
                      ),
                      IconButton(
                        tooltip: l10n.commonDelete,
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
              label: Text(l10n.settingsAddLlm),
            ),
          ],
        ),

        // ---------------- 自定义 Prompt ----------------
        _section(
          title: l10n.settingsPromptSectionTitle,
          subtitle: l10n.settingsPromptSectionSubtitle,
          children: [
            TextField(
              controller: _promptInput,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.settingsPromptHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.settingsPromptSplitButton),
                onPressed: () => _addPromptRule(useLlm: true),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.settingsPromptDirectButton),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.settingsPromptEmpty,
                      style: const TextStyle(color: Colors.grey)),
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
    final l10n = context.l10n;
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
    var testOk = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? l10n.settingsEditLlmTitle : l10n.settingsAddLlmTitle),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(name, l10n.settingsLlmFieldName),
                  _field(baseUrl, l10n.settingsLlmFieldBaseUrl),
                  _field(model, l10n.settingsLlmFieldModel),
                  _field(apiKey, l10n.settingsLlmFieldApiKey, obscure: true),
                  Row(children: [
                    Expanded(child: _field(temperature, l10n.settingsLlmFieldTemperature, num: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(maxTokens, l10n.settingsLlmFieldMaxTokens, num: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(timeout, l10n.settingsLlmFieldTimeout, num: true)),
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
                              testOk = error == null;
                              testResult = error == null
                                  ? l10n.settingsLlmTestOk(
                                      client.probedEndpoint ?? client.endpoint)
                                  : resolveL10nMsg(l10n, error);
                            });
                          },
                    icon: testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering),
                    label: Text(testing ? l10n.commonTesting : l10n.commonTestConnection),
                  ),
                  if (testResult != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        testResult!,
                        style: TextStyle(
                          color: testOk ? Colors.green : Colors.red,
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
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonSave),
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
            name.text.trim().isEmpty ? l10n.settingsLlmUnnamed : name.text.trim(),
            config: config,
            apiKey: apiKey.text,
          );
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsLlmSaved)));
    }
  }

  Future<void> _deleteProfile(LlmProfile profile) async {
    final l10n = context.l10n;
    final spacesUsing = ref
        .read(spacesProvider)
        .spaces
        .where((s) => s.llmProfileId == profile.id)
        .map((s) => s.name)
        .toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLlmDeleteTitle(profile.name)),
        content: Text(spacesUsing.isEmpty
            ? l10n.settingsLlmDeleteUnused
            : l10n.settingsLlmDeleteInUse(spacesUsing.join(l10n.commonJoinSeparator))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(llmProfilesProvider.notifier).delete(profile.id);
  }

  Future<void> _addPromptRule({required bool useLlm}) async {
    final l10n = context.l10n;
    final text = _promptInput.text.trim();
    if (text.isEmpty) return;
    final llm = ref.read(llmClientProvider);

    if (useLlm) {
      if (llm == null) {
        _toast(resolveL10nMsg(l10n, ref.read(llmUnavailableReasonProvider)));
        return;
      }
      _toast(l10n.settingsPromptSplitting);
      try {
        final generator = RuleGenerators(
            llm: llm, store: ref.read(rulesProvider.notifier).store);
        final drafts = await generator.draftFromUserPrompt(text);
        if (!mounted || drafts.isEmpty) return;
        final checks = List<bool>.filled(drafts.length, true);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.settingsPromptConfirmTitle),
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
                        subtitle: Text(ruleCategoryLabel(l10n, drafts[i].$1)),
                        dense: true,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.settingsPromptAddSelected),
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
          _toast(l10n.settingsPromptAddedRules(added));
        }
      } catch (e) {
        _toast(l10n.settingsPromptSplitFailed(e.toString()));
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
      _toast(l10n.settingsPromptAddedOne);
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
