import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/date_format.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/model_labels.dart';
import '../../models/rule.dart';
import '../../providers/app_providers.dart';

/// 规则库：全部回复规则 + 来源追溯 + 版本历史 + 手动管理。
class RulesPage extends ConsumerStatefulWidget {
  const RulesPage({super.key});

  @override
  ConsumerState<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends ConsumerState<RulesPage> {
  RuleSourceType? _filterSource;
  RuleCategory? _filterCategory;
  bool _filterEnabledOnly = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(rulesProvider);
    var rules = state.rules.toList();
    if (_filterSource != null) {
      rules = rules.where((r) => r.source.type == _filterSource).toList();
    }
    if (_filterCategory != null) {
      rules = rules.where((r) => r.category == _filterCategory).toList();
    }
    if (_filterEnabledOnly) {
      rules = rules.where((r) => r.enabled).toList();
    }
    if (_search.isNotEmpty) {
      rules = rules
          .where((r) => r.content.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Text(l10n.navRules, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 12),
              Text(
                l10n.rulesEnabledSummary(state.enabled.length, state.rules.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _addManualRule,
                icon: const Icon(Icons.add),
                label: Text(l10n.rulesAddManual),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: l10n.rulesSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              _sourceChip(null, l10n.rulesFilterAllSources),
              for (final t in RuleSourceType.values)
                _sourceChip(t, ruleSourceTypeLabel(l10n, t)),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.rulesFilterEnabledOnly),
                selected: _filterEnabledOnly,
                onSelected: (v) => setState(() => _filterEnabledOnly = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.rules.isEmpty && state.loaded
              ? Center(
                  child: Text(l10n.rulesEmpty,
                      textAlign: TextAlign.center),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: rules.length,
                  itemBuilder: (context, i) => _RuleTile(rule: rules[i]),
                ),
        ),
      ],
    );
  }

  Widget _sourceChip(RuleSourceType? type, String label) => ChoiceChip(
        label: Text(label),
        selected: _filterSource == type && (type != null || _filterSource == null),
        onSelected: (_) => setState(() => _filterSource = type),
      );

  Future<void> _addManualRule() async {
    final l10n = context.l10n;
    final content = TextEditingController();
    var category = RuleCategory.other;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.rulesAddManualTitle),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: content,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.rulesFieldContent,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RuleCategory>(
                  initialValue: category,
                  decoration: InputDecoration(labelText: l10n.rulesFieldCategory),
                  items: [
                    for (final c in RuleCategory.values)
                      DropdownMenuItem(
                          value: c, child: Text(ruleCategoryLabel(l10n, c))),
                  ],
                  onChanged: (v) =>
                      v == null ? null : setDialogState(() => category = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.commonAdd)),
          ],
        ),
      ),
    );
    if (ok == true && content.text.trim().isNotEmpty) {
      await ref
          .read(rulesProvider.notifier)
          .addManual(content.text.trim(), category);
    }
  }
}

class _RuleTile extends ConsumerWidget {
  const _RuleTile({required this.rule});

  final Rule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _openDetail(context),
        leading: Icon(
          rule.enabled ? Icons.check_circle : Icons.cancel_outlined,
          color: rule.enabled ? Colors.green : Colors.grey,
        ),
        title: Text(rule.content, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${ruleSourceTypeLabel(l10n, rule.source.type)} · '
          '${ruleCategoryLabel(l10n, rule.category)}'
          '${rule.version > 1 ? " · v${rule.version}" : ""}'
          '${rule.supersededBy != null ? " · ${l10n.rulesSuperseded}" : ""}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rule.stats.usedCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: l10n.rulesStatsTooltip(rule.stats.usedCount,
                      rule.stats.keptUnchangedCount, rule.stats.editedCount),
                  child: Text(
                    l10n.rulesUsedTimes(rule.stats.usedCount),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Switch(
              value: rule.enabled,
              onChanged: (v) =>
                  ref.read(rulesProvider.notifier).setEnabled(rule.id, v),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _RuleDetailDialog(rule: rule),
    );
  }
}

/// 规则详情：内容 + 来源明细 + 版本历史 + 编辑/删除。
class _RuleDetailDialog extends ConsumerStatefulWidget {
  const _RuleDetailDialog({required this.rule});

  final Rule rule;

  @override
  ConsumerState<_RuleDetailDialog> createState() => _RuleDetailDialogState();
}

class _RuleDetailDialogState extends ConsumerState<_RuleDetailDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // 从 provider 里取最新版（编辑后内容会变）。
    final rule = ref
            .watch(rulesProvider)
            .rules
            .where((r) => r.id == widget.rule.id)
            .firstOrNull ??
        widget.rule;

    return AlertDialog(
      title: Text(l10n.rulesDetailTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rule.content, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 12),
              _kv(l10n.rulesKvCategory, ruleCategoryLabel(l10n, rule.category)),
              _kv(
                  l10n.rulesKvStatus,
                  rule.enabled
                      ? l10n.rulesStatusEnabled
                      : (rule.supersededBy != null
                          ? l10n.rulesStatusSuperseded
                          : l10n.rulesStatusDisabled)),
              _kv(l10n.rulesKvVersion, 'v${rule.version}'),
              _kv(
                  l10n.rulesKvStats,
                  l10n.rulesStatsDetail(rule.stats.usedCount,
                      rule.stats.keptUnchangedCount, rule.stats.editedCount)),
              const Divider(height: 24),
              Text(l10n.rulesSourceSection,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              _kv(l10n.rulesKvType, ruleSourceTypeLabel(l10n, rule.source.type)),
              if (rule.source.generatedBy.isNotEmpty)
                _kv(l10n.rulesKvGeneratedBy, rule.source.generatedBy),
              _kv(l10n.rulesKvCreatedAt,
                  formatDateTimeShort(context, rule.source.createdAt)),
              ..._sourceDetails(rule),
              if (rule.history.isNotEmpty) ...[
                const Divider(height: 24),
                Text(l10n.rulesHistorySection,
                    style: Theme.of(context).textTheme.titleSmall),
                for (final h in rule.history.reversed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('v${h.version} · ${formatDateTimeShort(context, h.updatedAt)}'),
                        Text(h.content,
                            style: const TextStyle(color: Colors.grey)),
                        if (h.reason.isNotEmpty)
                          Text(l10n.rulesChangeReason(h.reason),
                              style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
        OutlinedButton.icon(
          onPressed: () => _editContent(context, rule),
          icon: const Icon(Icons.edit, size: 16),
          label: Text(l10n.commonEdit),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.rulesDeleteTitle),
                content: Text(l10n.rulesDeleteContent),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.commonCancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.commonDelete)),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(rulesProvider.notifier).delete(rule.id);
              if (context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.delete_outline, size: 16),
          label: Text(l10n.commonDelete),
        ),
      ],
    );
  }

  List<Widget> _sourceDetails(Rule rule) {
    final l10n = context.l10n;
    final d = rule.source.details;
    switch (rule.source.type) {
      case RuleSourceType.emailHistory:
        final ids = (d['message_ids'] as List? ?? []).cast<String>();
        final range = d['date_range']?.toString() ?? '';
        return [
          if (range.isNotEmpty) _kv(l10n.rulesKvDateRange, range),
          if (ids.isNotEmpty)
            _kv(l10n.rulesKvSourceMails, l10n.rulesSourceMailsDetail(ids.length)),
        ];
      case RuleSourceType.knowledgeBase:
        return [
          _kv(l10n.rulesKvDoc, d['doc']?.toString() ?? ''),
          _kv(l10n.rulesKvDocVersion, (d['doc_hash']?.toString() ?? '').substring(0, 12)),
        ];
      case RuleSourceType.userPrompt:
        return [_kv(l10n.rulesKvUserPrompt, d['prompt_text']?.toString() ?? '')];
      case RuleSourceType.draftFeedback:
        return [
          if (d['draft_id'] != null) _kv(l10n.rulesKvSourceDraft, d['draft_id'].toString()),
          if (d['change_summary'] != null)
            _kv(l10n.rulesKvChangeSummary, d['change_summary'].toString()),
          if (d['reason'] != null) _kv(l10n.rulesKvReason, d['reason'].toString()),
        ];
      case RuleSourceType.manual:
        return [
          Text(ruleSourceTypeLabel(l10n, RuleSourceType.manual),
              style: const TextStyle(color: Colors.grey))
        ];
    }
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(k,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            Expanded(
                child: Text(v,
                    style: const TextStyle(fontSize: 12, height: 1.4))),
          ],
        ),
      );

  Future<void> _editContent(BuildContext dialogContext, Rule rule) async {
    final l10n = dialogContext.l10n;
    final controller = TextEditingController(text: rule.content);
    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text(l10n.rulesEditContentTitle),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonSave)),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      // 变更原因与规则正文一样按中文存储（规则资产本身设计为中文）。
      await ref
          .read(rulesProvider.notifier)
          .updateContent(rule.id, controller.text.trim(), '手动编辑');
    }
    controller.dispose();
  }
}
