import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              Text('规则库', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 12),
              Text(
                '启用 ${state.enabled.length} / 共 ${state.rules.length} 条',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _addManualRule,
                icon: const Icon(Icons.add),
                label: const Text('手动添加'),
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
                  decoration: const InputDecoration(
                    hintText: '搜索规则内容',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              _sourceChip(null, '全部来源'),
              for (final t in RuleSourceType.values) _sourceChip(t, t.label),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('只看启用'),
                selected: _filterEnabledOnly,
                onSelected: (v) => setState(() => _filterEnabledOnly = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.rules.isEmpty && state.loaded
              ? const Center(
                  child: Text('规则库为空：去「学习中心」学习历史邮件、\n'
                      '「知识库」导入文档、或「设置」添加自定义 Prompt',
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
    final content = TextEditingController();
    var category = RuleCategory.other;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('手动添加规则'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: content,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '规则内容',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RuleCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: '类目'),
                  items: [
                    for (final c in RuleCategory.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
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
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('添加')),
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
          '${rule.source.type.label} · ${rule.category.label}'
          '${rule.version > 1 ? " · v${rule.version}" : ""}'
          '${rule.supersededBy != null ? " · 已被新规则取代" : ""}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rule.stats.usedCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: '使用 ${rule.stats.usedCount} 次 · '
                      '未改直接发 ${rule.stats.keptUnchangedCount} 次 · '
                      '被修改 ${rule.stats.editedCount} 次',
                  child: Text(
                    '${rule.stats.usedCount}次',
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
    // 从 provider 里取最新版（编辑后内容会变）。
    final rule = ref
            .watch(rulesProvider)
            .rules
            .where((r) => r.id == widget.rule.id)
            .firstOrNull ??
        widget.rule;

    return AlertDialog(
      title: Text('规则详情'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rule.content, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 12),
              _kv('类目', rule.category.label),
              _kv('状态',
                  rule.enabled ? '启用' : (rule.supersededBy != null ? '已被取代' : '停用')),
              _kv('当前版本', 'v${rule.version}'),
              _kv('使用统计',
                  '使用 ${rule.stats.usedCount} 次 / 未改发送 ${rule.stats.keptUnchangedCount} / 被修改 ${rule.stats.editedCount}'),
              const Divider(height: 24),
              Text('来源（这条规则怎么来的）',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              _kv('类型', rule.source.type.label),
              if (rule.source.generatedBy.isNotEmpty)
                _kv('生成模型', rule.source.generatedBy),
              _kv('生成时间', rule.source.createdAt.toIso8601String().substring(0, 19)),
              ..._sourceDetails(rule),
              if (rule.history.isNotEmpty) ...[
                const Divider(height: 24),
                Text('版本历史', style: Theme.of(context).textTheme.titleSmall),
                for (final h in rule.history.reversed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('v${h.version} · ${h.updatedAt.toIso8601String().substring(0, 19)}'),
                        Text(h.content,
                            style: const TextStyle(color: Colors.grey)),
                        if (h.reason.isNotEmpty)
                          Text('变更原因：${h.reason}',
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
          child: const Text('关闭'),
        ),
        OutlinedButton.icon(
          onPressed: () => _editContent(context, rule),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('编辑'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('删除规则'),
                content: const Text('删除后不可恢复（含版本历史）。确定？'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除')),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(rulesProvider.notifier).delete(rule.id);
              if (context.mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('删除'),
        ),
      ],
    );
  }

  List<Widget> _sourceDetails(Rule rule) {
    final d = rule.source.details;
    switch (rule.source.type) {
      case RuleSourceType.emailHistory:
        final ids = (d['message_ids'] as List? ?? []).cast<String>();
        final range = d['date_range']?.toString() ?? '';
        return [
          if (range.isNotEmpty) _kv('邮件日期范围', range),
          if (ids.isNotEmpty)
            _kv('来源邮件数', '${ids.length} 封（Message-ID 已记录在学习状态中，'
                '不会重复学习）'),
        ];
      case RuleSourceType.knowledgeBase:
        return [
          _kv('文档', d['doc']?.toString() ?? ''),
          _kv('文档版本', (d['doc_hash']?.toString() ?? '').substring(0, 12)),
        ];
      case RuleSourceType.userPrompt:
        return [_kv('用户 Prompt', d['prompt_text']?.toString() ?? '')];
      case RuleSourceType.draftFeedback:
        return [
          if (d['draft_id'] != null) _kv('来源草稿', d['draft_id'].toString()),
          if (d['change_summary'] != null)
            _kv('修改摘要', d['change_summary'].toString()),
          if (d['reason'] != null) _kv('优化原因', d['reason'].toString()),
        ];
      case RuleSourceType.manual:
        return [const Text('手动添加', style: TextStyle(color: Colors.grey))];
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
    final controller = TextEditingController(text: rule.content);
    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('编辑规则内容'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(rulesProvider.notifier)
          .updateContent(rule.id, controller.text.trim(), '手动编辑');
    }
    controller.dispose();
  }
}
