import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// locale 感知的日期时间格式化。
/// 依赖 main() 里的 initializeDateFormatting() 预载符号表。

/// 简短格式：zh/en 均为 `2026-10-08 14:32`。
String formatDateTimeShort(BuildContext context, DateTime time) =>
    DateFormat('yyyy-MM-dd HH:mm', Localizations.localeOf(context).toString())
        .format(time);

/// 带星期：zh「2026-10-08（周三）14:32」/ en「Wed, Oct 8, 2026 14:32」。
String formatDateTimeWithWeekday(BuildContext context, DateTime time) {
  final locale = Localizations.localeOf(context).toString();
  if (locale.startsWith('zh')) {
    return DateFormat('yyyy-MM-dd（EEE）HH:mm', locale).format(time);
  }
  return DateFormat('EEE, MMM d, yyyy HH:mm', locale).format(time);
}

/// 纯日期：zh/en 均为 `2026-10-08`。
String formatDateShort(BuildContext context, DateTime time) =>
    DateFormat('yyyy-MM-dd', Localizations.localeOf(context).toString())
        .format(time);
