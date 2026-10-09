import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'paths.dart';

/// 应用日志：写入数据目录 `logs/app.log`，同时输出到调试控制台。
///
/// 收信 / 学习等关键链路的节点日志都走这里，问题复现后无需 flutter run
/// 控制台，直接读日志文件即可定位（路径见 `AppPaths.logsDir`）。
/// 写入失败静默——日志绝不能影响业务；禁止把 token / 密码明文写进日志。
class AppLog {
  AppLog._();

  /// 单文件上限：超过后滚动为 app.log.1（只保留一代），避免无限增长。
  static const _maxLogBytes = 1024 * 1024;

  static File? _file;
  static bool _initTried = false;

  /// 逐行串行写链：保证行序，也避免并发打开同一文件互相覆盖。
  static Future<void> _chain = Future.value();

  /// 应用启动时调用一次（须在 AppPaths.init 之后）。
  static Future<void> init() async {
    if (_initTried) return;
    _initTried = true;
    try {
      final dir = AppPaths.instance.logsDir;
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, 'app.log'));
      if (await file.exists() && await file.length() > _maxLogBytes) {
        final rolled = File('${file.path}.1');
        if (await rolled.exists()) await rolled.delete();
        await file.rename(rolled.path);
      }
      _file = file;
    } catch (e) {
      debugPrint('[log] 日志文件初始化失败（仅控制台输出）：$e');
    }
  }

  static void log(String tag, String message) {
    final line = '${DateTime.now().toIso8601String()} [$tag] $message';
    debugPrint('[$tag] $message');
    final file = _file;
    if (file == null) return; // init 未完成/失败：仅控制台。
    // 每行独立「打开-追加-落盘」：常驻 IOSink 的缓冲在挂死场景下会丢行
    //（实测丢过 5 行），取证场景必须逐行可靠。串到写链上保证顺序。
    _chain = _chain.then((_) async {
      try {
        await file.writeAsString('$line\n',
            mode: FileMode.append, flush: true);
      } catch (_) {
        // 日志写失败不影响业务。
      }
    });
  }
}
