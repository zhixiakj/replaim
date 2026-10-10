/// provider / 服务层无法拿到 BuildContext，用户可见文案以 (key, args)
/// 结构化存进状态或异常，UI 层经 resolve_msg.dart 的 resolveL10nMsg
/// 按当前 locale 渲染。
///
/// key 即 ARB 中的 camelCase key；args 可嵌套 L10nMsg（如
/// 「发送失败 + LocalizedError」），解析时递归展开。
class L10nMsg {
  const L10nMsg(this.key, [this.args = const []]);

  final String key;
  final List<Object> args;

  /// 日志 / 无 context 场景的兜底显示（只出 key，不出用户文案）。
  @override
  String toString() => key;
}

/// 携带本地化消息的异常：服务层 throw，UI 捕获后用
/// [errToMsg] + resolveL10nMsg 渲染成当前语言。
class LocalizedError implements Exception {
  const LocalizedError(this.msg);

  final L10nMsg msg;

  @override
  String toString() => msg.key;
}

/// 任意异常 / 错误值转可展示文案：LocalizedError 用其携带的消息，
/// 其余原样 toString（英文界面下深层库错误会透出原文，属预期兜底）。
L10nMsg errToMsg(Object e) {
  if (e is LocalizedError) return e.msg;
  return L10nMsg('commonRawError', [e.toString()]);
}
