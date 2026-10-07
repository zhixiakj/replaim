import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

/// 知识库：导入文档（复制进应用目录）、hash 变更检测、生成规则。
class KbPage extends ConsumerWidget {
  const KbPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kbProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text('知识库', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: state.busy ? null : () => _pickFiles(ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('导入 .md / .txt 文档'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: state.busy ? null : () => ref.read(kbProvider.notifier).generateRules(),
              icon: state.busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(state.busy ? '生成中…' : '为待生成文档生成规则'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '售后政策 / FAQ / 商品信息 → 提炼为回复规则；文档内容变更后可重新生成（旧规则会被替换）',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (state.progress.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(state.progress,
                style: const TextStyle(color: Colors.blue)),
          ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(state.message!,
                style: const TextStyle(color: Colors.green)),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(state.error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        if (state.docs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: Text('暂无文档。导入 .md / .txt 文件后即可生成回复规则')),
          ),
        for (final doc in state.docs)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                doc.needsRuleGeneration
                    ? Icons.pending_actions
                    : Icons.task_alt,
                color: doc.needsRuleGeneration
                    ? Colors.orange
                    : Colors.green,
              ),
              title: Text(doc.fileName),
              subtitle: Text(
                '导入于 ${doc.importedAt.substring(0, 19)} · ${(doc.sizeBytes / 1024).toStringAsFixed(1)} KB · '
                '内容 ${doc.contentHash.substring(0, 10)} · '
                '${doc.ruleGeneratedHash == null ? "尚未生成规则" : (doc.needsRuleGeneration ? "内容已变更，待重新生成" : "规则已是最新")}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除文档',
                onPressed: () => ref.read(kbProvider.notifier).remove(doc.fileName),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickFiles(WidgetRef ref) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt', 'markdown'],
    );
    final paths =
        files.map((f) => f.path).whereType<String>().toList();
    if (paths.isNotEmpty) {
      await ref.read(kbProvider.notifier).import(paths);
    }
  }
}
