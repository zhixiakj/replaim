import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ARB 双语守卫：en 是 gen-l10n 的模板（类型与回退来源），zh 缺 key 时
/// 运行时静默回退英文——破坏「界面中英双语并重」的承诺。
/// 任何一侧新增 key 而另一侧漏译，这里应立刻红。
void main() {
  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final en = load('lib/l10n/app_en.arb');
  final zh = load('lib/l10n/app_zh.arb');
  final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
  final zhKeys = zh.keys.where((k) => !k.startsWith('@')).toSet();

  test('zh 与 en ARB 的 key 完全一致', () {
    final zhOnly = zhKeys.difference(enKeys);
    final enOnly = enKeys.difference(zhKeys);
    expect(zhOnly, isEmpty, reason: 'zh 多出（en 模板没有）：$zhOnly');
    expect(enOnly, isEmpty, reason: 'zh 缺失（会回退英文）：$enOnly');
  });

  test('带占位符的 key 都有 @ 元数据声明（防参数类型静默漂移）', () {
    final missing = <String>[];
    for (final k in enKeys) {
      final value = en[k];
      if (value is String &&
          RegExp(r'\{[a-z][a-zA-Z]*\}').hasMatch(value) &&
          !en.containsKey('@$k')) {
        missing.add(k);
      }
    }
    expect(missing, isEmpty, reason: '缺少 @ 元数据：$missing');
  });
}
