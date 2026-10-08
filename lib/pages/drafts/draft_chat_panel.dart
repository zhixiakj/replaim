import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/draft_record.dart';
import '../../providers/app_providers.dart';

/// 草稿编辑页右侧的 AI 对话面板：用自然语言指示修改左侧草稿正文。
///
/// 对话记录随草稿持久化（DraftRecord.chatHistory），重新打开可继续。
class DraftChatPanel extends ConsumerStatefulWidget {
  const DraftChatPanel({
    super.key,
    required this.draftId,
    required this.enabled,
    required this.onApplied,
  });

  final String draftId;

  /// 草稿仍可编辑时才允许对话（已发送 / 已丢弃即停用）。
  final bool enabled;

  /// AI 改稿成功，把新正文同步给左侧编辑区。
  final void Function(String body) onApplied;

  @override
  ConsumerState<DraftChatPanel> createState() => _DraftChatPanelState();
}

class _DraftChatPanelState extends ConsumerState<DraftChatPanel> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  DraftRecord? _recordOf(DraftsState state) => state.records
      .where((r) => r.id == widget.draftId)
      .firstOrNull;

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy || !widget.enabled) return;
    final record = _recordOf(ref.read(draftsProvider));
    if (record == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(draftsProvider.notifier).refineDraft(record, text);
      _input.clear();
      widget.onApplied(result.body);
    } catch (e) {
      if (mounted) setState(() => _error = '修改失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 新一轮对话落盘后（provider reload）滚到最新消息。
    ref.listen(draftsProvider, (prev, next) {
      final prevLen =
          _recordOf(prev ?? const DraftsState())?.chatHistory.length ?? 0;
      final nextLen = _recordOf(next)?.chatHistory.length ?? 0;
      if (nextLen > prevLen) _jumpToBottom();
    });
    final record = _recordOf(ref.watch(draftsProvider));
    final messages = record?.chatHistory ?? const <DraftChatMessage>[];
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text('AI 改稿',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '告诉 AI 怎么改，修改后的正文会自动更新到左侧',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: messages.isEmpty && !_busy
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.enabled
                          ? '和 AI 对话来修改草稿，例如：\n「语气更诚恳一点」「开头加上感谢反馈」「去掉具体天数承诺」'
                          : '草稿已定稿，对话已停用',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (_busy ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: _BusyBubble(),
                      );
                    }
                    final m = messages[i];
                    return m.isUser
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: _UserBubble(text: m.text),
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: _AssistantBubble(message: m),
                          );
                  },
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(_error!,
                style: const TextStyle(color: Colors.red), maxLines: 3),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: widget.enabled && !_busy,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '告诉 AI 怎么修改草稿…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: (widget.enabled && !_busy) ? _send : null,
                icon: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('修改'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: SelectableText(text, style: const TextStyle(height: 1.4)),
    );
  }
}

/// AI 回复气泡：一句话概括 + 可展开的应用后完整正文。
class _AssistantBubble extends StatefulWidget {
  const _AssistantBubble({required this.message});

  final DraftChatMessage message;

  @override
  State<_AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends State<_AssistantBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = widget.message;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(m.text, style: const TextStyle(height: 1.4)),
          if (m.body != null) ...[
            const SizedBox(height: 6),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: scheme.primary,
                    ),
                    Text(
                      _expanded ? '收起正文' : '正文已更新，点击查看',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(m.body!,
                    style: const TextStyle(height: 1.5, fontSize: 12.5)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BusyBubble extends StatelessWidget {
  const _BusyBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('AI 正在修改草稿…',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
