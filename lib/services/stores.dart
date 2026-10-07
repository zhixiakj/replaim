import 'dart:io';

import '../models/draft_record.dart';
import '../models/learn_state.dart';
import 'id_gen.dart';
import 'paths.dart';
import 'yaml_io.dart';

/// 学习状态存储（learn_state.yaml）。
class LearnStateStore {
  LearnStateStore([File? file])
      : _file = file ?? File(AppPaths.instance.learnStateFile);

  final File _file;
  LearnState _state = LearnState.empty();

  LearnState get state => _state;

  Future<void> load() async {
    final map = readYamlMap(_file);
    _state = map != null ? LearnState.fromMap(map) : LearnState.empty();
  }

  Future<void> recordRun(List<ConsumedEmail> consumedEmails) async {
    _state = _state.withAdded(consumedEmails, DateTime.now());
    await writeYamlFile(_file, _state.toMap());
  }
}

/// 草稿存储（`drafts/<id>.yaml`，每条草稿一个文件，便于追溯）。
class DraftStore {
  DraftStore([Directory? dir])
      : _dir = dir ?? Directory(AppPaths.instance.draftsDir);

  final Directory _dir;

  File _fileFor(String id) => File('${_dir.path}/$id.yaml');

  Future<void> save(DraftRecord record) =>
      writeYamlFile(_fileFor(record.id), record.toMap());

  Future<void> delete(String id) async {
    final f = _fileFor(id);
    if (f.existsSync()) await f.delete();
  }

  /// 按创建时间倒序列出全部草稿。
  Future<List<DraftRecord>> listAll() async {
    if (!_dir.existsSync()) return [];
    final records = <DraftRecord>[];
    for (final entity in _dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.yaml')) continue;
      final map = readYamlMap(entity);
      if (map != null) records.add(DraftRecord.fromMap(map));
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<DraftRecord?> findById(String id) async {
    final map = readYamlMap(_fileFor(id));
    return map != null ? DraftRecord.fromMap(map) : null;
  }

  /// 该来信是否已有进行中的草稿（避免重复起草）。
  Future<DraftRecord?> findEditingByEmail(String emailMessageId) async {
    final all = await listAll();
    for (final r in all) {
      if (r.emailMessageId == emailMessageId &&
          r.status == DraftStatus.editing) {
        return r;
      }
    }
    return null;
  }

  String newId() => newDraftId();
}
