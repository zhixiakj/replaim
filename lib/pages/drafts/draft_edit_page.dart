import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/draft_record.dart';
import '../../providers/app_providers.dart';

/// 草稿编辑页：展示 LLM 原始草稿 → 用户编辑 → 发送 → 反馈学习。
class DraftEditPage extends ConsumerStatefulWidget {
  const DraftEditPage({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<DraftEditPage> createState() => _DraftEditPageState();
}

class _DraftEditPageState extends ConsumerState<DraftEditPage> {
  late final TextEditingController _editor;
  final TextEditingController _ccInput = TextEditingController();
  bool _sending = false;
  DraftRecord? _record;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _editor = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _editor.dispose();
    _ccInput.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = ref.read(draftsProvider);
    final record = state.records
        .where((r) => r.id == widget.draftId)
        .firstOrNull;
    if (record != null) {
      _record = record;
      _editor.text = record.originalDraft;
    }
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (record == null) {
      return const Center(child: Text('草稿不存在'));
    }
    final rules = ref.watch(rulesProvider).rules;
    final usedRules =
        rules.where((r) => record.usedRuleIds.contains(r.id)).toList();
    final sent = record.status == DraftStatus.sentEdited ||
        record.status == DraftStatus.sentUnmodified;
    final space = ref.watch(currentSpaceProvider).space;
    final sender = space?.resolveSender(record.accountId);
    final editable = !sent && record.status != DraftStatus.discarded;

    return Scaffold(
      appBar: AppBar(
        title: Text('回复：${record.subject}'),
        actions: [
          if (!sent && record.status != DraftStatus.discarded) ...[
            TextButton(
              onPressed: _sending ? null : _discard,
              child: const Text('丢弃'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_sending ? '发送中…' : '确认发送'),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
        Text('收件人：${record.toAddress}',
            style: Theme.of(context).textTheme.bodyMedium),
        Text(
          '发信账号：${sender?.email ?? "（空间内无可用发信账号）"}'
          '${sender != null && sender.id != record.accountId ? "（收信账号未开发信，使用默认发信账号）" : ""}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text('生成模型：${record.llmGeneratedBy}',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            sent
                ? '状态：${record.status.label}'
                : '草稿由回复规则生成，可直接编辑；发送时会对比修改并自动优化规则。',
            style: TextStyle(
              color: sent ? Colors.green : Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: TextField(
              controller: _editor,
              maxLines: 18,
              enabled: editable,
              style: const TextStyle(height: 1.6),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          if (editable) ...[
            const SizedBox(height: 12),
            Text('抄送（转发场景自动识别的原始收件地址，可增删）',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final cc in record.extraCc)
                  InputChip(
                    label: Text(cc),
                    onDeleted: () =>
                        setState(() => record.extraCc.remove(cc)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ccInput,
                    decoration: const InputDecoration(
                      hintText: '添加抄送地址',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addCc(record),
                  ),
                ),
                IconButton(
                  tooltip: '添加',
                  icon: const Icon(Icons.add),
                  onPressed: () => _addCc(record),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text('本草稿依据的回复规则（${usedRules.length} 条）'),
            subtitle: Text('草稿只依据规则生成，规则未覆盖的内容不会编造', style: Theme.of(context).textTheme.bodySmall,),
            children: [
              for (final r in usedRules)
                ListTile(
                  dense: true,
                  leading: Icon(
                    r.enabled ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color: r.enabled ? Colors.green : Colors.grey,
                  ),
                  title: Text(r.content),
                  subtitle: Text(
                      '${r.category.label} · 来源：${r.source.type.label}'),
                ),
            ],
          ),
          if (record.wasModified && record.ruleUpdates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('发送后规则优化记录',
                        style: Theme.of(context).textTheme.titleSmall),
                    for (final u in record.ruleUpdates)
                      Text('· [${u.action}] ${u.summary}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addCc(DraftRecord record) {
    final v = _ccInput.text.trim().toLowerCase();
    if (v.isEmpty || record.extraCc.contains(v)) {
      _ccInput.clear();
      return;
    }
    setState(() => record.extraCc.add(v));
    _ccInput.clear();
  }

  Future<void> _send() async {
    final record = _record;
    if (record == null) return;
    final text = _editor.text.trim();
    if (text.isEmpty) return;

    // 二次确认：外发动作。
    final ccNote = record.extraCc.isEmpty
        ? ''
        : '\n抄送：${record.extraCc.join('、')}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认发送'),
        content: Text(
            '将发送到 ${record.toAddress}$ccNote\n主题：Re: ${record.subject}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('再改改'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('发送'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _sending = true);
    final success =
        await ref.read(draftsProvider.notifier).send(record, text);
    if (!mounted) return;
    setState(() => _sending = false);
    final feedback = ref.read(draftsProvider).feedbackMessage;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedback ?? '已发送')));
      await _reloadRecord();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(draftsProvider).error ?? '发送失败')));
    }
  }

  Future<void> _reloadRecord() async {
    await ref.read(draftsProvider.notifier).reload();
    final records = ref.read(draftsProvider).records;
    final updated =
        records.where((r) => r.id == widget.draftId).firstOrNull;
    if (updated != null && mounted) {
      setState(() => _record = updated);
    }
  }

  Future<void> _discard() async {
    final record = _record;
    if (record == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('丢弃草稿'),
        content: const Text('丢弃后不可恢复，也不会发送。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('丢弃'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(draftsProvider.notifier).discard(record);
    if (mounted) Navigator.pop(context);
  }
}
