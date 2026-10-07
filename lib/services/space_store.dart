import 'dart:io';

import '../models/mail_space.dart';
import 'id_gen.dart';
import 'paths.dart';
import 'yaml_io.dart';

/// 空间存储：`spaces/<id>/space.yaml` 的加载与变更。
///
/// 各 store 仅构造时解析一次文件路径；[spacesDir]/[appStateFile] 仅测试注入。
class SpaceStore {
  SpaceStore({Directory? spacesDir, File? appStateFile})
      : _spacesDir = spacesDir ?? Directory(AppPaths.instance.spacesDir),
        _appStateFile = appStateFile ?? File(AppPaths.instance.appStateFile);

  final Directory _spacesDir;
  final File _appStateFile;

  Future<List<MailSpace>> loadAll() async {
    if (!_spacesDir.existsSync()) return [];
    final spaces = <MailSpace>[];
    for (final entity in _spacesDir.listSync()) {
      if (entity is! Directory) continue;
      final map = readYamlMap(File('${entity.path}/space.yaml'));
      if (map != null) spaces.add(MailSpace.fromMap(map));
    }
    spaces.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return spaces;
  }

  Future<bool> hasAnySpace() async => (await loadAll()).isNotEmpty;

  /// 创建空间：建目录 + 写初始 space.yaml。
  Future<MailSpace> create(String name) async {
    final space = MailSpace(id: newSpaceId(), name: name);
    await save(space);
    return space;
  }

  Future<void> save(MailSpace space) async {
    await Directory('${_spacesDir.path}/${space.id}').create(recursive: true);
    await writeYamlFile(
        File('${_spacesDir.path}/${space.id}/space.yaml'), space.toMap());
  }

  /// 删除空间目录（整个分区数据）。敏感信息由调用方按账号 ID 清理。
  Future<void> delete(String spaceId) async {
    final dir = Directory('${_spacesDir.path}/$spaceId');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  // ---------------- 当前空间选择 ----------------

  Future<String?> loadCurrentSpaceId() async {
    final map = readYamlMap(_appStateFile);
    final id = map?['current_space_id'] as String?;
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<void> saveCurrentSpaceId(String? spaceId) async {
    await writeYamlFile(_appStateFile, {'current_space_id': spaceId ?? ''});
  }
}
