import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/email_summary.dart';
import '../../providers/app_providers.dart';
import '../drafts/draft_edit_page.dart';

/// 收件箱：左列表右详情（桌面双栏）。
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(inboxProvider).messages.isEmpty) {
        ref.read(inboxProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxProvider);
    final selected = state.selected;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text('收件箱', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      tooltip: '刷新',
                      onPressed: state.loading
                          ? null
                          : () => ref.read(inboxProvider.notifier).refresh(),
                      icon: state.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(state.error!,
                      style: const TextStyle(color: Colors.red)),
                ),
              Expanded(
                child: state.messages.isEmpty && !state.loading
                    ? const Center(child: Text('暂无邮件，请先配置邮箱并刷新'))
                    : ListView.builder(
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) {
                          final m = state.messages[i];
                          return _MailTile(
                            email: m,
                            selected: selected?.messageId == m.messageId,
                            onTap: () => ref
                                .read(inboxProvider.notifier)
                                .select(m),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: selected == null
              ? const Center(child: Text('选择一封邮件查看详情'))
              : _MailDetail(email: selected),
        ),
      ],
    );
  }
}

class _MailTile extends StatelessWidget {
  const _MailTile({required this.email, required this.selected, this.onTap});

  final EmailSummary email;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = email.parsedDate;
    final dateText = date == null
        ? ''
        : '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return ListTile(
      selected: selected,
      onTap: onTap,
      title: Text(
        email.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(email.fromAddress,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(email.snippet,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      isThreeLine: true,
      trailing: Text(dateText, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _MailDetail extends ConsumerWidget {
  const _MailDetail({required this.email});

  final EmailSummary email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    final drafts = ref.watch(draftsProvider);
    final generating = drafts.generating;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                email.subject,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: generating ? null : () => _generateDraft(context, ref),
              icon: generating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(generating ? '生成中…' : '依据规则生成草稿'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('发件人：${email.fromAddress}　·　${email.date}'),
        if (inbox.threadPeers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('本线程往来（${inbox.threadPeers.length} 封）',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final p in inbox.threadPeers)
            Text(
              '· ${p.date} ${p.fromAddress}：${p.snippet}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
        const Divider(height: 32),
        SelectableText(
          email.bodyText.isEmpty ? email.snippet : email.bodyText,
          style: const TextStyle(height: 1.6, fontSize: 14),
        ),
        if (drafts.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(drafts.error!,
                style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Future<void> _generateDraft(BuildContext context, WidgetRef ref) async {
    final id =
        await ref.read(draftsProvider.notifier).generateFor(email);
    if (id != null && context.mounted) {
      ref.read(draftsProvider.notifier).clearMessages();
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DraftEditPage(draftId: id),
      ));
    }
  }
}
