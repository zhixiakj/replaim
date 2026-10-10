import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/space_store.dart';

/// 界面语言：null = 跟随系统（非中英环境回落英文，由 supportedLocales 顺序保证）。
/// 初始值由 main() 启动时从 app_state.yaml 读出并 overrideWith 注入，避免启动闪变。
final localeProvider =
    NotifierProvider<LocaleSettingsNotifier, Locale?>(LocaleSettingsNotifier.new);

class LocaleSettingsNotifier extends Notifier<Locale?> {
  LocaleSettingsNotifier([this.initial]);

  final Locale? initial;

  @override
  Locale? build() => initial;

  /// 切换语言：即时生效（MaterialApp locale 变化触发整树重建），并落盘。
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await SpaceStore().saveLanguage(locale?.languageCode);
  }
}
