import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/paths.dart';
import 'services/space_migrator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPaths.init();
  await AppPaths.instance.ensureAll();
  // 旧版单空间布局 → 默认空间（全新安装 / 已迁移时为空操作）。
  await SpaceMigrator().migrateIfNeeded();
  runApp(const ProviderScope(child: ReplaimApp()));
}
