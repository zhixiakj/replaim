import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/date_format.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/resolve_msg.dart';
import '../../providers/app_providers.dart';

/// 学习中心：历史邮件增量学习 + 已消费邮件清单。
class LearnPage extends ConsumerWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(learnProvider);
    final space = ref.watch(currentSpaceProvider).space;
    // 学习文件夹按账号配置（各服务商命名不同），展示用去重合集
    //（停用账号不参与学习，也不展示）。
    final learnFolders = <String>{
      for (final a in space?.accounts ?? const [])
        if (a.enabled) ...a.learnFolders,
    }.toList();
    final learnMonths = space?.learnMonths ?? 12;
    final notifier = ref.read(learnProvider.notifier);
    final consumed = notifier.learnState.consumed;
    final recent = consumed.length > 200 ? consumed.sublist(consumed.length - 200) : consumed;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text(l10n.navLearn, style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: state.running
                  ? null
                  : () => _confirmResetLearning(context, ref),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(l10n.learnReset),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: state.running
                  ? null
                  : () => ref.read(learnProvider.notifier).runLearning(),
              icon: state.running
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.school),
              label: Text(state.running ? l10n.learnRunning : l10n.learnStart),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.learnIntro(
              learnFolders.join(l10n.commonJoinSeparator), learnMonths),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (state.running) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.progress == null
                      ? l10n.learnProcessing
                      : resolveL10nMsg(l10n, state.progress!)),
                  const SizedBox(height: 8),
                  if (state.total > 0)
                    LinearProgressIndicator(
                        value: state.done / state.total),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (state.resultMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(resolveL10nMsg(l10n, state.resultMessage!),
                style: const TextStyle(color: Colors.green)),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(resolveL10nMsg(l10n, state.error!),
                style: const TextStyle(color: Colors.red)),
          ),
        if (state.failedFolders.isNotEmpty)
          Card(
            color: Colors.orange.shade50,
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.orange.shade800),
                      const SizedBox(width: 6),
                      Text(l10n.learnFailedFoldersTitle,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final f in state.failedFolders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(f, style: const TextStyle(fontSize: 13)),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.learnFailedFoldersHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.learnStatusSection,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(l10n.learnConsumedCount(consumed.length)),
                Text(state.lastRunAt == null
                    ? l10n.learnNever
                    : l10n.learnLastRun(
                        formatDateTimeShort(context, state.lastRunAt!))),
                const SizedBox(height: 12),
                if (consumed.isEmpty)
                  Text(l10n.learnNoRecords,
                      style: const TextStyle(color: Colors.grey))
                else ...[
                  Text(l10n.learnRecentSection,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final c in recent.reversed.take(50))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mark_email_read_outlined,
                          size: 18, color: Colors.grey),
                      title: Text(
                        c.subject.isEmpty ? l10n.learnNoSubject : c.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${c.folder} · ${c.date.substring(0, 10)} · '
                        '${l10n.learnGeneratedRules(c.generatedRuleIds.length)}',
                        maxLines: 1,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 重置学习记录：确认后清空「已消费邮件」（不动已生成的规则），
/// 下次学习会重新读取全部历史邮件。
Future<void> _confirmResetLearning(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.learnResetTitle),
      content: Text(l10n.learnResetContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.learnResetConfirm),
        ),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(learnProvider.notifier).resetLearning();
  }
}
