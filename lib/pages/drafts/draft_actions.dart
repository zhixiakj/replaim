import 'package:flutter/material.dart';

import '../../models/draft_record.dart';

/// 草稿操作确认对话框：草稿编辑页与会话页草稿气泡共用。

/// 删除草稿。
Future<bool> confirmDeleteDraft(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除草稿'),
      content: const Text('删除后不可恢复（不会发送）。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
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
  var runFeedback = true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialog) => AlertDialog(
        title: const Text('标注为已发送'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '用于「已在本应用之外（如邮箱网页版）手工发送这封草稿」的情况。\n'
              '标注后，该内容会计入后续草稿生成与学习的参考。',
              style: TextStyle(height: 1.4),
            ),
            CheckboxListTile(
              value: runFeedback,
              onChanged: (v) => setDialog(() => runFeedback = v ?? false),
              title: const Text('对比我的修改并优化规则'),
              subtitle: const Text('若你在其他平台又改动过内容，请取消勾选'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('标注'),
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
  final ccNote = record.extraCc.isEmpty
      ? ''
      : '\n抄送：${record.extraCc.join('、')}';
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('确认发送'),
      content: Text(
          '将发送到 ${record.toAddress}$ccNote\n主题：Re: ${record.subject}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('再改改'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('发送'),
        ),
      ],
    ),
  );
  return ok == true;
}
