import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 应用数据目录布局（`<ApplicationSupport>/replaim/`）：
///
///   app_state.yaml             全局应用状态（当前空间 ID 等）
///   llm_profiles.yaml          全局 LLM Profile 注册表（非敏感字段）
///   logs/app.log               应用运行日志（超限滚动为 app.log.1）
///   `spaces/<spaceId>/`        每个空间一个目录：
///     space.yaml               空间元数据 + 账号列表 + 学习偏好
///     rules/rules.yaml         本空间规则库（核心资产）
///     learn_state.yaml         本空间历史邮件学习状态
///     knowledge_base/          本空间知识库文档副本 + kb_index.yaml
///     drafts/                  本空间草稿记录（每条一个 YAML）
///     inbox_cache/             本空间收件箱离线缓存（每账号一个 YAML）
///
/// 旧版单空间布局（config/ rules/ learn_state.yaml knowledge_base/ drafts/
/// 直接位于根下）由 SpaceMigrator 在启动时迁移，legacy* 路径仅供迁移读取。
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

  /// 测试用：指定根目录（同时设为单例，供各 store 解析默认路径）。
  static AppPaths forTest(String root) => _instance = AppPaths._(root);

  static AppPaths get instance {
    assert(_instance != null, 'AppPaths.init() 必须先调用');
    return _instance!;
  }

  // ---------------- 全局 ----------------

  String get appStateFile => p.join(root, 'app_state.yaml');
  String get llmProfilesFile => p.join(root, 'llm_profiles.yaml');
  Directory get logsDir => Directory(p.join(root, 'logs'));
  String get spacesDir => p.join(root, 'spaces');

  // ---------------- 空间分区 ----------------

  Directory spaceDir(String spaceId) => Directory(p.join(spacesDir, spaceId));
  File spaceFile(String spaceId) =>
      File(p.join(spaceDir(spaceId).path, 'space.yaml'));
  File rulesFileFor(String spaceId) =>
      File(p.join(spaceDir(spaceId).path, 'rules', 'rules.yaml'));
  Directory kbDirFor(String spaceId) =>
      Directory(p.join(spaceDir(spaceId).path, 'knowledge_base'));
  File kbIndexFileFor(String spaceId) =>
      File(p.join(kbDirFor(spaceId).path, 'kb_index.yaml'));
  File learnStateFileFor(String spaceId) =>
      File(p.join(spaceDir(spaceId).path, 'learn_state.yaml'));
  Directory draftsDirFor(String spaceId) =>
      Directory(p.join(spaceDir(spaceId).path, 'drafts'));
  Directory inboxCacheDirFor(String spaceId) =>
      Directory(p.join(spaceDir(spaceId).path, 'inbox_cache'));

  // ---------------- 旧版布局（仅迁移读取） ----------------

  String get legacyConfigDir => p.join(root, 'config');
  File get legacyConfigFile => File(p.join(legacyConfigDir, 'app_config.yaml'));
  File get legacyRulesFile => File(p.join(root, 'rules', 'rules.yaml'));
  File get legacyLearnStateFile => File(p.join(root, 'learn_state.yaml'));
  Directory get legacyKbDir => Directory(p.join(root, 'knowledge_base'));
  Directory get legacyDraftsDir => Directory(p.join(root, 'drafts'));

  /// 确保全部子目录存在。
  Future<void> ensureAll() async {
    await Directory(spacesDir).create(recursive: true);
  }
}
