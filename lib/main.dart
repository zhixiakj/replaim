import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/locale_provider.dart';
import 'services/app_log.dart';
import 'services/paths.dart';
import 'services/space_migrator.dart';
import 'services/space_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPaths.init();
  await AppPaths.instance.ensureAll();
  await AppLog.init();
  AppLog.log('boot', '应用启动，数据目录：${AppPaths.instance.root}');
  // 旧版单空间布局 → 默认空间（全新安装 / 已迁移时为空操作）。
  await SpaceMigrator().migrateIfNeeded();
  // intl DateFormat 的 locale 符号表（星期名等），UI 日期格式化依赖。
  initializeDateFormatting();
  // 界面语言在 runApp 前读盘注入，避免首帧语言闪变。
  final language = await SpaceStore().loadLanguage();
  runApp(ProviderScope(
    overrides: [
      localeProvider.overrideWith(
        () => LocaleSettingsNotifier(
            language == null ? null : Locale(language)),
      ),
    ],
    child: const ReplaimApp(),
  ));
}
