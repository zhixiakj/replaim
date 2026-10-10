import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/date_format.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/resolve_msg.dart';
import '../../models/conversation.dart';
import '../../models/draft_record.dart';
import '../../models/email_summary.dart';
import '../../providers/app_providers.dart';
import '../drafts/draft_actions.dart';
import '../drafts/draft_edit_page.dart';

/// 收件箱（聊天式）：左侧为按「发件人 × 收件人」参与人集合汇总的会话列表，
/// 收到的与发出的邮件合并进同一会话（不按方向分段），已回复的会话标记
/// 「已回」（最新来件之后已有我方发出）；
/// 右侧以聊天气泡展示会话往来 —— 对方来信靠左、本空间发出的邮件靠右。
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  final _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(inboxProvider).refreshed) {
        ref.read(inboxProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(inboxProvider);
    final selected = state.selectedConversation;

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
                    Text(l10n.navInbox, style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    if (state.loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      PopupMenuButton<String>(
                        tooltip: l10n.inboxRefreshTooltip,
                        icon: const Icon(Icons.refresh),
                        onSelected: (value) => ref
                            .read(inboxProvider.notifier)
                            .refresh(fullResync: value == 'full'),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'incremental',
                              child: Text(l10n.inboxRefreshIncremental)),
                          PopupMenuItem(
                              value: 'full',
                              child: Text(l10n.inboxRefreshFull)),
                        ],
                      ),
                  ],
                ),
              ),
              if (state.loading && state.syncingLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Text(
                    resolveL10nMsg(l10n, state.syncingLabel!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              if (state.errors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    state.errors
                        .map((e) => resolveL10nMsg(l10n, e))
                        .join(l10n.commonErrorSeparator),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: state.conversations.isEmpty && !state.loading
                    ? Center(child: Text(l10n.inboxEmpty))
                    : Scrollbar(
                        controller: _listScrollController,
                        child: ListView.builder(
                          controller: _listScrollController,
                          itemCount: state.conversations.length,
                          itemBuilder: (context, i) {
                            final conv = state.conversations[i];
                            return _ConversationTile(
                              conversation: conv,
                              selected: selected?.key == conv.key,
                              onTap: () => ref
                                  .read(inboxProvider.notifier)
                                  .selectConversation(conv),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: selected == null
              ? Center(child: Text(l10n.inboxNoSelection))
              : _ChatDetail(conversation: selected),
        ),
      ],
    );
  }
}

String _formatShortDate(DateTime? date) {
  if (date == null) return '';
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final mi = date.minute.toString().padLeft(2, '0');
  return '$mm-$dd $hh:$mi';
}

/// 详情弹窗用的完整时间：zh「2026-10-08（周三）14:32」/ en「Wed, Oct 8, 2026 14:32」。
String _formatFullDate(BuildContext context, DateTime? date) {
  if (date == null) return '';
  return formatDateTimeWithWeekday(context, date);
}

/// 头像底色：按参与人串做稳定散列取色相，同一会话跨重启颜色不变
/// （不用 String.hashCode，它在每次运行间不稳定）。
Color _avatarColor(String seed) {
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return HSVColor.fromAHSV(0.62, (h % 360).toDouble(), 0.42, 0.92).toColor();
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    this.onTap,
  });

  final Conversation conversation;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = conversation.lastMessage;
    final title = conversation.participants.isEmpty
        ? l10n.inboxInternalConversation
        : conversation.participants.join(l10n.commonJoinSeparator);
    final snippet = last.snippet.isEmpty ? l10n.inboxNoBody : last.snippet;
    return ListTileTheme(
      data: ListTileThemeData(
        selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: ListTile(
        selected: selected,
        onTap: onTap,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _avatarColor(conversation.key),
          child: Text(
            title.isEmpty ? '?' : title[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        title: Row(
          children: [
            if (conversation.hasForwarded) ...[
              Tooltip(
                message: l10n.inboxForwardedTooltip,
                child: Icon(Icons.forward_to_inbox,
                    size: 16, color: Colors.orange.shade800),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (conversation.replied) ...[
              const SizedBox(width: 6),
              _ReplyBadge(
                label: l10n.inboxRepliedBadge,
                background: Colors.green.shade100,
                color: Colors.green.shade900,
              ),
            ],
          ],
        ),
        subtitle: Text(
          conversation.lastFromMe ? l10n.inboxMePrefix(snippet) : snippet,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(_formatShortDate(last.parsedDate),
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

/// 会话列表上的回复状态小徽章（待回 / 已回）。
class _ReplyBadge extends StatelessWidget {
  const _ReplyBadge({
    required this.label,
    required this.background,
    required this.color,
  });

  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 会话详情：顶部参与人与生成草稿操作条，下方时间升序的气泡往来。
class _ChatDetail extends ConsumerStatefulWidget {
  const _ChatDetail({required this.conversation});

  final Conversation conversation;

  @override
  ConsumerState<_ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends ConsumerState<_ChatDetail> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _jumpToBottomAfterFrame();
  }

  @override
  void didUpdateWidget(covariant _ChatDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换会话、刷新带来新邮件或草稿数量变化时停在最新一条。
    final records = ref.read(draftsProvider).records;
    final oldDraftCount =
        _visibleDrafts(oldWidget.conversation, records).length;
    final newDraftCount = _visibleDrafts(widget.conversation, records).length;
    if (oldWidget.conversation.key != widget.conversation.key ||
        oldWidget.conversation.messages.length !=
            widget.conversation.messages.length ||
        oldDraftCount != newDraftCount) {
      _jumpToBottomAfterFrame();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToBottomAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// 会话时间线里应展示的草稿：
  /// - 编辑中的始终展示；
  /// - 已发送（含手工标注）在「对应的真实邮件尚未同步进缓存」时过渡展示
  ///   （正文或引用头+主题能匹配到会话我方邮件即让位，避免重复）；
  /// - 已丢弃、与本会话无关的不展示。
  List<DraftRecord> _visibleDrafts(
      Conversation conv, List<DraftRecord> all) {
    final msgIds = conv.messages.map((m) => m.messageId).toSet();
    final participants =
        conv.participants.map((p) => p.toLowerCase()).toSet();
    final myMails = conv.messages.where((m) => conv.isFromMe(m)).toList();
    final mySentBodies = myMails
        .map((m) => m.bodyText.trim())
        .where((t) => t.isNotEmpty)
        .toSet();
    // 引用头 + 归一化主题匹配：列表阶段真实邮件正文未回填时也能识别已同步。
    final repliedAnchors = myMails
        .where((m) => m.inReplyTo != null && m.inReplyTo!.isNotEmpty)
        .map((m) => '${m.inReplyTo}|${m.normalizedSubject}')
        .toSet();
    return all.where((d) {
      final anchored = msgIds.contains(d.emailMessageId) ||
          participants.contains(d.toAddress.toLowerCase());
      if (!anchored) return false;
      switch (d.status) {
        case DraftStatus.editing:
          return true;
        case DraftStatus.sentManually:
        case DraftStatus.sentUnmodified:
        case DraftStatus.sentEdited:
          final text = (d.finalSentText ?? '').trim();
          if (text.isEmpty || mySentBodies.contains(text)) return false;
          return !repliedAnchors.contains(
              '${d.emailMessageId}|${EmailSummary.normalizeSubject(d.subject)}');
        case DraftStatus.discarded:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final conv = widget.conversation;
    final inbox = ref.watch(inboxProvider);
    final drafts = ref.watch(draftsProvider);
    final generating = drafts.generating;
    final space = ref.watch(currentSpaceProvider).space;
    final selected = inbox.selectedMessage;
    final convDrafts = _visibleDrafts(conv, drafts.records);
    final title = conv.participants.isEmpty
        ? l10n.inboxInternalConversation
        : conv.participants.join(l10n.commonJoinSeparator);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: title,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                  '${l10n.inboxMessagesCount(conv.messages.length)}'
                  '${convDrafts.isEmpty ? '' : ' · ${l10n.inboxDraftsCount(convDrafts.length)}'}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected == null
                      ? (conv.latestIncoming == null
                          ? l10n.inboxNoIncoming
                          : l10n.inboxTapToSelect)
                      : l10n.inboxSelected(selected.subject),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: (generating || selected == null)
                    ? null
                    : () => _generateDraft(context),
                icon: generating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(generating ? l10n.inboxGenerating : l10n.inboxGenerateDraft),
              ),
            ],
          ),
        ),
        if (selected != null && selected.originalRecipients.isNotEmpty) ...[
          _ForwardedWarning(
              email: selected,
              accountEmail:
                  space?.accountById(selected.accountId)?.email ?? ''),
        ],
        if (drafts.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(resolveL10nMsg(l10n, drafts.error!),
                style: const TextStyle(color: Colors.red)),
          ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final maxBubbleWidth = constraints.maxWidth * 0.65;
            // 邮件与草稿混排，按时间升序（草稿编辑中按创建时间、已发送按发送时间）。
            final timeline = <(DateTime, Object)>[
              for (final m in conv.messages)
                (m.parsedDate ?? DateTime(2000), m as Object),
              for (final d in convDrafts)
                (
                  DateTime.tryParse(
                          d.sentAt?.toIso8601String() ?? d.createdAt) ??
                      DateTime(2000),
                  d as Object
                ),
            ]..sort((a, b) => a.$1.compareTo(b.$1));
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: timeline.length,
              itemBuilder: (context, i) {
                final item = timeline[i].$2;
                if (item is DraftRecord) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: _DraftBubble(
                        record: item, maxWidth: maxBubbleWidth),
                  );
                }
                final m = item as EmailSummary;
                final fromMe = conv.isFromMe(m);
                final accountEmail =
                    space?.accountById(m.accountId)?.email ?? '';
                return Align(
                  alignment: fromMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: fromMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!fromMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _showEmailDetails(context, m),
                              child: Text(
                                m.fromAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                      _MessageBubble(
                        email: m,
                        fromMe: fromMe,
                        accountEmail: accountEmail,
                        selected:
                            inbox.selectedMessage?.messageId == m.messageId,
                        maxWidth: maxBubbleWidth,
                        onTap: () => ref
                            .read(inboxProvider.notifier)
                            .selectMessage(m),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Future<void> _generateDraft(BuildContext context) async {
    final email = ref.read(inboxProvider).selectedMessage;
    if (email == null) return;
    final id = await ref.read(draftsProvider.notifier).generateFor(email);
    if (id != null && context.mounted) {
      ref.read(draftsProvider.notifier).clearMessages();
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DraftEditPage(draftId: id),
      ));
    }
  }
}

class _ForwardedWarning extends StatelessWidget {
  const _ForwardedWarning({required this.email, required this.accountEmail});

  final EmailSummary email;
  final String accountEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.forward_to_inbox,
                  size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.inboxForwardedWarning(
                    email.originalRecipients.join(l10n.commonJoinSeparator),
                    accountEmail,
                  ),
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 会话时间线里的草稿气泡：右侧对齐、描边区分，带编辑 / 发送 /
/// 标注已发送 / 删除操作（手工标注的仅可删除）。
class _DraftBubble extends ConsumerStatefulWidget {
  const _DraftBubble({required this.record, required this.maxWidth});

  final DraftRecord record;
  final double maxWidth;

  @override
  ConsumerState<_DraftBubble> createState() => _DraftBubbleState();
}

class _DraftBubbleState extends ConsumerState<_DraftBubble> {
  bool _busy = false;

  DraftRecord get record => widget.record;

  Future<void> _send() async {
    if (_busy) return;
    if (!await confirmSendDraft(context, record)) return;
    setState(() => _busy = true);
    final ok = await ref
        .read(draftsProvider.notifier)
        .send(record, record.effectiveText);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = context.l10n;
    final state = ref.read(draftsProvider);
    final msg = ok
        ? (state.feedbackMessage == null
            ? l10n.inboxSentFallback
            : resolveL10nMsg(l10n, state.feedbackMessage!))
        : (state.error == null
            ? l10n.inboxSendFailed
            : resolveL10nMsg(l10n, state.error!));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _markSent() async {
    if (_busy) return;
    final confirmed = await confirmMarkDraftSentManually(context);
    if (confirmed == null) return;
    setState(() => _busy = true);
    await ref
        .read(draftsProvider.notifier)
        .markManuallySent(record, runFeedback: confirmed.runFeedback);
    if (!mounted) return;
    setState(() => _busy = false);
    final feedback = ref.read(draftsProvider).feedbackMessage;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(feedback == null
            ? context.l10n.inboxMarkedSentFallback
            : resolveL10nMsg(context.l10n, feedback))));
  }

  Future<void> _delete() async {
    if (_busy) return;
    if (!await confirmDeleteDraft(context)) return;
    await ref.read(draftsProvider.notifier).deleteDraft(record);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final editing = record.status == DraftStatus.editing;
    final manual = record.status == DraftStatus.sentManually;
    final (chipColor, chipText) = switch (record.status) {
      DraftStatus.editing => (Colors.orange.shade800, l10n.inboxChipDraft),
      DraftStatus.sentManually =>
        (Colors.green.shade800, l10n.inboxChipSentManual),
      _ => (Colors.green.shade800, l10n.inboxChipSent),
    };
    final date = _formatShortDate(DateTime.tryParse(
        record.sentAt?.toIso8601String() ?? record.createdAt));

    Widget action(IconData icon, String label, VoidCallback onPressed) =>
        TextButton.icon(
          onPressed: _busy ? null : onPressed,
          icon: Icon(icon, size: 15),
          label: Text(label),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: editing ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: editing
              ? Colors.orange.shade300
              : Colors.green.shade300,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(chipText,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: chipColor)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.inboxReplySubject(record.subject),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            record.effectiveText,
            style: const TextStyle(height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            editing
                ? l10n.inboxDraftPendingNote(date)
                : l10n.inboxDraftCountedNote(date),
            style:
                TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              if (editing) ...[
                action(Icons.edit, l10n.commonEdit, () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              DraftEditPage(draftId: record.id)),
                    )),
                action(Icons.send, _busy ? l10n.commonSending : l10n.commonSend, _send),
                action(Icons.mark_email_read_outlined, l10n.inboxMarkSent,
                    _markSent),
              ],
              if (editing || manual)
                action(Icons.delete_outline, l10n.commonDelete, _delete),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.email,
    required this.fromMe,
    required this.accountEmail,
    required this.selected,
    required this.maxWidth,
    this.onTap,
  });

  final EmailSummary email;
  final bool fromMe;
  final String accountEmail;
  final bool selected;
  final double maxWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final body = email.bodyText.isEmpty ? email.snippet : email.bodyText;
    // Listener 在指针下压阶段即触发（先于子组件手势竞技），
    // 保证点在 SelectableText 正文上也能选中气泡。
    return Listener(
      onPointerDown: (_) => onTap?.call(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            color: fromMe
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: fromMe
                  ? const Radius.circular(12)
                  : const Radius.circular(4),
              bottomRight: fromMe
                  ? const Radius.circular(4)
                  : const Radius.circular(12),
            ),
            // 常驻边框宽度，选中只变色，避免布局抖动。
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                email.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                body,
                style: const TextStyle(height: 1.5, fontSize: 14),
              ),
              const SizedBox(height: 4),
              // Gmail 式「to me ▾」：meta 行整体 + 下拉箭头打开邮件详情弹窗。
              // 箭头在气泡内，外层 Listener 仍会先选中气泡，两者语义兼容。
              Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message: l10n.inboxEmailDetails,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showEmailDetails(context, email),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatShortDate(email.parsedDate)} · '
                          '${fromMe ? l10n.inboxSentVia(accountEmail) : l10n.inboxReceivedVia(accountEmail)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(Icons.expand_more,
                            size: 15, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showEmailDetails(BuildContext context, EmailSummary email) =>
    showDialog(
      context: context,
      builder: (_) => _EmailDetailsDialog(email: email),
    );

/// Gmail 风格的邮件详情弹窗：from / to / cc / date / mailed-by / signed-by。
///
/// 正文区整体 SelectionArea 包裹，所有文字可拖选复制；mailed-by / signed-by
/// 仅在 Authentication-Results 推导出域名时显示。老缓存邮件缺这些字段时，
/// 打开瞬间按 UID 现拉补取（ensureDetails），补到后 watch 自动刷新。
class _EmailDetailsDialog extends ConsumerStatefulWidget {
  const _EmailDetailsDialog({required this.email});

  final EmailSummary email;

  @override
  ConsumerState<_EmailDetailsDialog> createState() =>
      _EmailDetailsDialogState();
}

class _EmailDetailsDialogState extends ConsumerState<_EmailDetailsDialog> {
  bool _attemptDone = false;

  @override
  void initState() {
    super.initState();
    final e = widget.email;
    if (e.uid != null &&
        e.ccAddresses.isEmpty &&
        e.mailedBy.isEmpty &&
        e.signedBy.isEmpty) {
      ref
          .read(inboxProvider.notifier)
          .ensureDetails(e)
          .whenComplete(() {
        if (mounted) setState(() => _attemptDone = true);
      });
    }
  }

  /// 弹窗期间状态里的最新副本（补取成功后 storageKey 相同、字段更全）。
  EmailSummary _liveOf(List<EmailSummary> messages) {
    final key = widget.email.storageKey;
    for (final m in messages) {
      if (m.storageKey == key) return m;
    }
    return widget.email;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final email = _liveOf(ref.watch(inboxProvider).messages);
    final pending = email.uid != null &&
        email.ccAddresses.isEmpty &&
        email.mailedBy.isEmpty &&
        email.signedBy.isEmpty;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SelectableText(
                        email.subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectionArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'from', value: email.fromAddress),
                    _DetailRow(
                        label: 'to', value: email.toAddresses.join(', ')),
                    if (email.ccAddresses.isNotEmpty)
                      _DetailRow(
                          label: 'cc', value: email.ccAddresses.join(', ')),
                    _DetailRow(
                        label: 'date',
                        value: _formatFullDate(context, email.parsedDate)),
                    if (email.mailedBy.isNotEmpty)
                      _DetailRow(label: 'mailed-by', value: email.mailedBy),
                    if (email.signedBy.isNotEmpty)
                      _DetailRow(label: 'signed-by', value: email.signedBy),
                  ],
                ),
              ),
              if (pending) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!_attemptDone) ...[
                      const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _attemptDone
                          ? l10n.inboxAuthInfoMissing
                          : l10n.inboxAuthInfoLoading,
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// label 固定宽度 + 值可换行的详情行；值处于 SelectionArea 内，可选中复制。
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label,
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? context.l10n.commonEmptyValue : value,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
