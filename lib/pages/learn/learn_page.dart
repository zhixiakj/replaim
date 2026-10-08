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
            OutlinedButton.icon(
              onPressed: state.running
                  ? null
                  : () => _confirmResetLearning(context, ref),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('重置学习记录'),
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
              label: Text(state.running ? '学习中…' : '开始增量学习'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '从「${learnFolders.join('、')}」与收件箱近 $learnMonths 个月的历史中提炼回复规则：'
          '学习时自动把客户来信与你的回复按线程配对，从「问了什么 → 怎么答」中学习'
          '（空间内全部账号逐一学习）。'
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
                      Text('部分学习文件夹拉取失败',
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
                  const Text(
                    '请在「空间」页 → 学习偏好 → 历史学习文件夹 中改用服务器实际存在的'
                    '文件夹名，或点「从服务器读取文件夹列表」直接选择；常用已发送命名'
                    '（Sent / Sent Messages / Sent Items / 已发送）会自动匹配。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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

/// 重置学习记录：确认后清空「已消费邮件」（不动已生成的规则），
/// 下次学习会重新读取全部历史邮件。
Future<void> _confirmResetLearning(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('重置学习记录'),
      content: const Text(
          '将清空「已消费邮件」记录，不影响已生成的规则。下次「开始增量学习」会重新读取全部历史邮件。确定？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('重置'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(learnProvider.notifier).resetLearning();
  }
}
