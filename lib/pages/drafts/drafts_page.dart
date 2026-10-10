import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../l10n/model_labels.dart';
import '../../l10n/resolve_msg.dart';
import '../../models/draft_record.dart';
import '../../providers/app_providers.dart';
import 'draft_actions.dart';
import 'draft_edit_page.dart';

/// 草稿箱：全部草稿记录（编辑中 / 已发送 / 修改后发送 / 手工标注 / 已丢弃）。
class DraftsPage extends ConsumerWidget {
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(draftsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.navDrafts, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          l10n.draftsSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(resolveL10nMsg(l10n, state.message!),
                style: const TextStyle(color: Colors.blue)),
          ),
        const SizedBox(height: 16),
        if (state.records.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Center(child: Text(l10n.draftsEmpty)),
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
    final l10n = context.l10n;
    final rules = ref.watch(rulesProvider).rules;
    final usedCount =
        rules.where((r) => record.usedRuleIds.contains(r.id)).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(record.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          l10n.draftsTileSubtitle(
              record.toAddress, record.createdAt.substring(0, 16), usedCount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusChip(context, record.status),
            IconButton(
              tooltip: l10n.commonDelete,
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
    final l10n = context.l10n;
    final color = switch (status) {
      DraftStatus.editing => Colors.orange,
      DraftStatus.sentUnmodified => Colors.green,
      DraftStatus.sentEdited => Colors.blue,
      DraftStatus.sentManually => Colors.teal,
      DraftStatus.discarded => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(draftStatusLabel(l10n, status),
          style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
