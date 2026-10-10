import 'package:flutter/material.dart';

import '../../l10n/l10n_ext.dart';
import '../../models/draft_record.dart';

/// 草稿操作确认对话框：草稿编辑页与会话页草稿气泡共用。

/// 删除草稿。
Future<bool> confirmDeleteDraft(BuildContext context) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.draftConfirmDeleteTitle),
      content: Text(l10n.draftConfirmDeleteContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
  return ok == true;
}

/// 手工标注已发送（用户在其他平台发送了草稿内容）。
///
/// 返回 null = 取消；否则 [ConfirmMarkSent.runFeedback] 为是否同时
/// 做规则反馈学习（用户在外部又改动过内容时差异会失真，由用户取舍）。
Future<ConfirmMarkSent?> confirmMarkDraftSentManually(
    BuildContext context) async {
  final l10n = context.l10n;
  var runFeedback = true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialog) => AlertDialog(
        title: Text(l10n.draftMarkSentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.draftMarkSentContent,
              style: const TextStyle(height: 1.4),
            ),
            CheckboxListTile(
              value: runFeedback,
              onChanged: (v) => setDialog(() => runFeedback = v ?? false),
              title: Text(l10n.draftMarkSentFeedback),
              subtitle: Text(l10n.draftMarkSentFeedbackHint),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.draftMarkSentConfirm),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  return ConfirmMarkSent(runFeedback: runFeedback);
}

class ConfirmMarkSent {
  const ConfirmMarkSent({required this.runFeedback});

  final bool runFeedback;
}

/// 发送草稿（外发动作，二次确认）。
Future<bool> confirmSendDraft(BuildContext context, DraftRecord record) async {
  final l10n = context.l10n;
  final ccNote = record.extraCc.isEmpty
      ? ''
      : '\n${l10n.draftSendCcNote(record.extraCc.join(l10n.commonJoinSeparator))}';
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.draftConfirmSendTitle),
      content: Text(l10n.draftConfirmSendContent(
          record.toAddress, ccNote, record.subject)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.draftSendKeepEditing),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.commonSend),
        ),
      ],
    ),
  );
  return ok == true;
}
