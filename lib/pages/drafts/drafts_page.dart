import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/draft_record.dart';
import '../../providers/app_providers.dart';
import 'draft_actions.dart';
import 'draft_edit_page.dart';

/// 草稿箱：全部草稿记录（编辑中 / 已发送 / 修改后发送 / 手工标注 / 已丢弃）。
class DraftsPage extends ConsumerWidget {
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('草稿箱', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '发送时若草稿被修改，会自动分析修改并优化回复规则；'
          '未发送的草稿不会计入后续草稿生成与学习',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(state.message!,
                style: const TextStyle(color: Colors.blue)),
          ),
        const SizedBox(height: 16),
        if (state.records.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 64),
            child: Center(child: Text('暂无草稿，去邮件列表生成第一封吧')),
          ),
        for (final r in state.records) _DraftTile(record: r),
      ],
    );
  }
}

class _DraftTile extends ConsumerWidget {
  const _DraftTile({required this.record});

  final DraftRecord record;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDeleteDraft(context)) return;
    await ref.read(draftsProvider.notifier).deleteDraft(record);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider).rules;
    final usedCount =
        rules.where((r) => record.usedRuleIds.contains(r.id)).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(record.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${record.toAddress} · ${record.createdAt.substring(0, 16)} · '
              '依据 $usedCount 条规则',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusChip(context, record.status),
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DraftEditPage(draftId: record.id),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, DraftStatus status) {
    final (color, _) = switch (status) {
      DraftStatus.editing => (Colors.orange, '编辑中'),
      DraftStatus.sentUnmodified => (Colors.green, '已发送'),
      DraftStatus.sentEdited => (Colors.blue, '修改后发送'),
      DraftStatus.sentManually => (Colors.teal, '手工标注已发送'),
      DraftStatus.discarded => (Colors.grey, '已丢弃'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
