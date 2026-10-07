import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

/// 学习中心：历史邮件增量学习 + 已消费邮件清单。
class LearnPage extends ConsumerWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnProvider);
    final space = ref.watch(currentSpaceProvider).space;
    final learnFolders = space?.learnFolders ?? const ['Sent'];
    final learnMonths = space?.learnMonths ?? 12;
    final notifier = ref.read(learnProvider.notifier);
    final consumed = notifier.learnState.consumed;
    final recent = consumed.length > 200 ? consumed.sublist(consumed.length - 200) : consumed;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text('学习中心', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
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
              label: Text(state.running ? '学习中…' : '开始增量学习'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '从「${learnFolders.join('、')}」近 $learnMonths 个月的历史往来中提炼回复规则（空间内全部账号逐一学习）。'
          '已学习过的邮件不会重复使用；邮件按时间升序处理、冲突时新邮件优先，'
          '保证旧邮件不会覆盖新邮件沉淀的规则。学习范围可在「空间」页调整。',
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
                  Text(state.progress.isEmpty ? '正在处理…' : state.progress),
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
            child: Text(state.resultMessage!,
                style: const TextStyle(color: Colors.green)),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(state.error!, style: const TextStyle(color: Colors.red)),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('学习状态', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('已消费邮件：${consumed.length} 封'),
                Text('上次学习：${state.lastRunAt?.toIso8601String().substring(0, 19) ?? "从未"}'),
                const SizedBox(height: 12),
                if (consumed.isEmpty)
                  const Text('还没有学习记录。点击「开始增量学习」从历史邮件中提炼规则。',
                      style: TextStyle(color: Colors.grey))
                else ...[
                  Text('最近消费的邮件（最多显示 200 封）',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final c in recent.reversed.take(50))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mark_email_read_outlined,
                          size: 18, color: Colors.grey),
                      title: Text(
                        c.subject.isEmpty ? '（无主题）' : c.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${c.folder} · ${c.date.substring(0, 10)} · '
                        '产出规则 ${c.generatedRuleIds.length} 条',
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
