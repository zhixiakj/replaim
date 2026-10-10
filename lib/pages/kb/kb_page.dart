import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../l10n/resolve_msg.dart';
import '../../providers/app_providers.dart';

/// 知识库：导入文档（复制进应用目录）、hash 变更检测、生成规则。
class KbPage extends ConsumerWidget {
  const KbPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(kbProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text(l10n.navKb, style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: state.busy ? null : () => _pickFiles(ref),
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.kbImportButton),
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
              label: Text(state.busy ? l10n.inboxGenerating : l10n.kbGenerateButton),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.kbSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (state.progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(resolveL10nMsg(l10n, state.progress!),
                style: const TextStyle(color: Colors.blue)),
          ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(resolveL10nMsg(l10n, state.message!),
                style: const TextStyle(color: Colors.green)),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(resolveL10nMsg(l10n, state.error!),
                style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        if (state.docs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(child: Text(l10n.kbEmpty)),
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
                l10n.kbDocSubtitle(
                  doc.importedAt.substring(0, 19),
                  (doc.sizeBytes / 1024).toStringAsFixed(1),
                  doc.contentHash.substring(0, 10),
                  doc.ruleGeneratedHash == null
                      ? l10n.kbStatusPending
                      : (doc.needsRuleGeneration
                          ? l10n.kbStatusStale
                          : l10n.kbStatusFresh),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.kbDeleteDoc,
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
