import 'dart:io';

import '../models/app_config.dart';
import '../models/mail_space.dart';
import 'id_gen.dart';
import 'llm_profile_store.dart';
import 'paths.dart';
import 'secret_storage.dart';
import 'space_store.dart';
import 'yaml_io.dart';

/// 旧版单空间布局 → 空间布局的一次性迁移（幂等）。
///
/// 旧布局：根下直接放 config/app_config.yaml、rules/rules.yaml、
/// learn_state.yaml、knowledge_base/、drafts/，secrets 用扁平键
/// mail_password / llm_api_key。
///
/// 迁移动作：
/// 1. 创建「默认空间」，把规则 / 知识库 / 学习状态 / 草稿整体搬入空间目录；
/// 2. 旧 AppConfig.mail → 空间首个账号（收 + 发全开），
///    旧 AppConfig.llm → 首个 LLM Profile 并分配给空间；
/// 3. 旧扁平 secrets 复制到命名空间键（旧键保留不删，迁移失败可重试）；
/// 4. 学习偏好 / 输出语言随空间；默认空间设为当前空间。
///
/// 已有空间（含全新安装）时不做任何事；全新安装由用户自行创建第一个空间。
class SpaceMigrator {
  SpaceMigrator({
    SpaceStore? spaceStore,
    LlmProfileStore? llmStore,
    SecretStore? secrets,
  })  : _spaces = spaceStore ?? SpaceStore(),
        _llmStore = llmStore ?? LlmProfileStore(),
        _secrets = secrets ?? SecretStore();

  static const defaultSpaceName = '默认空间';

  final SpaceStore _spaces;
  final LlmProfileStore _llmStore;
  final SecretStore _secrets;

  /// 返回是否执行了迁移。
  Future<bool> migrateIfNeeded() async {
    final paths = AppPaths.instance;
    final hasLegacy = paths.legacyConfigFile.existsSync() ||
        paths.legacyRulesFile.existsSync();
    if (!hasLegacy) return false;
    if (await _spaces.hasAnySpace()) return false;

    final cfg = readYamlMap(paths.legacyConfigFile) ?? <String, dynamic>{};

    // 1. 创建默认空间并搬入数据。
    final space = await _spaces.create(defaultSpaceName);
    await _moveFile(paths.legacyRulesFile, paths.rulesFileFor(space.id));
    await _moveFile(
        paths.legacyLearnStateFile, paths.learnStateFileFor(space.id));
    await _moveDir(paths.legacyKbDir, paths.kbDirFor(space.id));
    await _moveDir(paths.legacyDraftsDir, paths.draftsDirFor(space.id));

    // 2. 邮箱账号 → 空间首个账号（收 + 发全开）。
    final oldMail = MailAccountConfig.fromMap(cfg['mail'] ?? {});
    if (oldMail.email.isNotEmpty || oldMail.isConfigured) {
      final account = oldMail.copyWith(
        id: newAccountId(),
        receiveEnabled: true,
        sendEnabled: true,
      );
      space.accounts.add(account);
      final legacyPwd = await _secrets.legacyMailPassword();
      if (legacyPwd != null && legacyPwd.isNotEmpty) {
        await _secrets.saveMailPassword(account.id, legacyPwd);
      }
      space.defaultSendAccountId = account.id;
    }

    // 3. LLM 配置 → 首个 Profile 并分配。
    final oldLlm = LlmConfig.fromMap(cfg['llm'] ?? {});
    if (oldLlm.isConfigured) {
      final profile = await _llmStore.create(name: '默认模型', config: oldLlm);
      final legacyKey = await _secrets.legacyLlmApiKey();
      if (legacyKey != null && legacyKey.isNotEmpty) {
        await _secrets.saveLlmApiKey(profile.id, legacyKey);
      }
      space.llmProfileId = profile.id;
    }

    // 4. 学习偏好 / 输出语言随空间。
    space.outputLanguage = cfg['output_language'] as String? ?? 'English';
    final folders = (cfg['learn_folders'] as List?)
        ?.map((e) => e.toString())
        .toList();
    if (folders != null && folders.isNotEmpty) {
      space.learnFolders
        ..clear()
        ..addAll(folders);
    }
    space.learnMonths = cfg['learn_months'] as int? ?? 12;
    space.learnMaxPerFolder = cfg['learn_max_per_folder'] as int? ?? 200;

    await _spaces.save(space);
    await _spaces.saveCurrentSpaceId(space.id);

    // 5. 旧配置内容已全部并入 space.yaml / llm_profiles.yaml，删除文件；
    //    清掉可能残留的旧目录（config/ 与空的 rules/）。
    if (paths.legacyConfigFile.existsSync()) {
      await paths.legacyConfigFile.delete();
    }
    await _pruneDirIfEmpty(Directory(paths.legacyConfigDir));
    await _pruneDirIfEmpty(paths.legacyRulesFile.parent);
    return true;
  }

  Future<void> _moveFile(File src, File dst) async {
    if (!src.existsSync()) return;
    await dst.parent.create(recursive: true);
    try {
      await src.rename(dst.path);
    } catch (_) {
      await dst.writeAsBytes(await src.readAsBytes(), flush: true);
      await src.delete();
    }
  }

  Future<void> _moveDir(Directory src, Directory dst) async {
    if (!src.existsSync()) return;
    await dst.parent.create(recursive: true);
    try {
      await src.rename(dst.path);
    } catch (_) {
      await _copyDir(src, dst);
      await src.delete(recursive: true);
    }
  }

  Future<void> _copyDir(Directory src, Directory dst) async {
    await dst.create(recursive: true);
    for (final entity in src.listSync()) {
      if (entity is File) {
        await File('${dst.path}/${entity.uri.pathSegments.last}')
            .writeAsBytes(await entity.readAsBytes(), flush: true);
      } else if (entity is Directory) {
        await _copyDir(entity, Directory('${dst.path}/${entity.uri.pathSegments.last}'));
      }
    }
  }

  Future<void> _pruneDirIfEmpty(Directory dir) async {
    if (!dir.existsSync()) return;
    try {
      if (dir.listSync().isEmpty) await dir.delete();
    } catch (_) {
      // 非空或占用则保留，无碍。
    }
  }
}
