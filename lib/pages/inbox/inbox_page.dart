import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation.dart';
import '../../models/email_summary.dart';
import '../../providers/app_providers.dart';
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
                    Text('邮件列表', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    if (state.loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      PopupMenuButton<String>(
                        tooltip: '刷新',
                        icon: const Icon(Icons.refresh),
                        onSelected: (value) => ref
                            .read(inboxProvider.notifier)
                            .refresh(fullResync: value == 'full'),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'incremental',
                              child: Text('刷新（只拉新邮件）')),
                          PopupMenuItem(
                              value: 'full',
                              child: Text('完全刷新（重建缓存）')),
                        ],
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
                child: state.conversations.isEmpty && !state.loading
                    ? const Center(child: Text('暂无邮件，请先在空间中配置账号并刷新'))
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
              ? const Center(child: Text('选择一个会话查看往来'))
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

/// 详情弹窗用的完整时间：2026-10-08（周三）14:32。
String _formatFullDate(DateTime? date) {
  if (date == null) return '';
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  final y = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final mi = date.minute.toString().padLeft(2, '0');
  return '$y-$mm-$dd（周${weekdays[date.weekday - 1]}）$hh:$mi';
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
    final last = conversation.lastMessage;
    final title = conversation.participants.isEmpty
        ? '（本空间内部往来）'
        : conversation.participants.join('、');
    final snippet = last.snippet.isEmpty ? '（无正文）' : last.snippet;
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
                message: '会话中含转发邮件，原始收件不在本空间账号内',
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
                label: '已回',
                background: Colors.green.shade100,
                color: Colors.green.shade900,
              ),
            ],
          ],
        ),
        subtitle: Text(
          conversation.lastFromMe ? '我：$snippet' : snippet,
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
    // 切换会话或刷新带来新邮件时停在最新一条。
    if (oldWidget.conversation.key != widget.conversation.key ||
        oldWidget.conversation.messages.length !=
            widget.conversation.messages.length) {
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

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    final inbox = ref.watch(inboxProvider);
    final drafts = ref.watch(draftsProvider);
    final generating = drafts.generating;
    final space = ref.watch(currentSpaceProvider).space;
    final selected = inbox.selectedMessage;
    final title =
        conv.participants.isEmpty ? '（本空间内部往来）' : conv.participants.join('、');

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
              Text('${conv.messages.length} 封往来（含已发出）',
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
                          ? '本会话暂无对方来件，无法生成草稿'
                          : '点击对方邮件气泡后可生成草稿')
                      : '选中：${selected.subject}',
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
                label: Text(generating ? '生成中…' : '依据规则生成草稿'),
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
            child: Text(drafts.error!,
                style: const TextStyle(color: Colors.red)),
          ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final maxBubbleWidth = constraints.maxWidth * 0.65;
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: conv.messages.length,
              itemBuilder: (context, i) {
                final m = conv.messages[i];
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
                  '检测到转发：客户原始收件地址为 ${email.originalRecipients.join('、')}，'
                  '（不在本空间账号内）。生成草稿时会默认通过 $accountEmail 发送并抄送上述地址，'
                  '可在草稿页调整。',
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
                  message: '邮件详情',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showEmailDetails(context, email),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatShortDate(email.parsedDate)} · '
                          '${fromMe ? '经 $accountEmail 发出' : '收信 $accountEmail'}',
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
                    tooltip: '关闭',
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
                        value: _formatFullDate(email.parsedDate)),
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
                          ? '未获取到发件认证信息（该邮件可能未提供，或网络不可用）'
                          : '正在获取发件认证信息…',
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
              value.isEmpty ? '（空）' : value,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
