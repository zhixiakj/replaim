import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 应用数据目录布局（`<ApplicationSupport>/replaim/`）：
///
///   config/app_config.yaml    非敏感配置
///   rules/rules.yaml          规则库（核心资产）
///   learn_state.yaml          历史邮件学习状态
///   knowledge_base/           知识库文档副本 + kb_index.yaml
///   drafts/                   草稿记录（每条一个 YAML）
///
/// [baseDir] 仅测试时注入。
class AppPaths {
  AppPaths._(this.root);

  final String root;

  static AppPaths? _instance;

  /// 初始化（应用启动时调用一次）。
  static Future<AppPaths> init() async {
    if (_instance != null) return _instance!;
    final support = await getApplicationSupportDirectory();
    return _instance = AppPaths._(p.join(support.path, 'replaim'));
  }

  /// 测试用：指定根目录。
  static AppPaths forTest(String root) => AppPaths._(root);

  static AppPaths get instance {
    assert(_instance != null, 'AppPaths.init() 必须先调用');
    return _instance!;
  }

  String get configDir => p.join(root, 'config');
  String get configFile => p.join(configDir, 'app_config.yaml');

  String get rulesDir => p.join(root, 'rules');
  String get rulesFile => p.join(rulesDir, 'rules.yaml');

  String get learnStateFile => p.join(root, 'learn_state.yaml');

  String get kbDir => p.join(root, 'knowledge_base');
  String get kbIndexFile => p.join(kbDir, 'kb_index.yaml');

  String get draftsDir => p.join(root, 'drafts');

  /// 确保全部子目录存在。
  Future<void> ensureAll() async {
    for (final dir in [configDir, rulesDir, kbDir, draftsDir]) {
      await Directory(dir).create(recursive: true);
    }
  }
}
