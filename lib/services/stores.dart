import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/draft_record.dart';
import '../models/email_summary.dart';
import '../models/learn_state.dart';
import 'id_gen.dart';
import 'paths.dart';
import 'yaml_io.dart';

/// 学习状态存储（空间内 learn_state.yaml）。
class LearnStateStore {
  LearnStateStore({String spaceId = '', File? file})
      : _file = file ?? AppPaths.instance.learnStateFileFor(spaceId);

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

/// 草稿存储（空间内 `drafts/<id>.yaml`，每条草稿一个文件，便于追溯）。
class DraftStore {
  DraftStore({String spaceId = '', Directory? dir})
      : _dir = dir ?? AppPaths.instance.draftsDirFor(spaceId);

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

/// 收件箱缓存条目：一个收信账号一份，含增量同步状态。
class InboxCacheEntry {
  InboxCacheEntry({
    required this.messages,
    this.uidValidity,
    this.lastUid,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  final List<EmailSummary> messages;

  /// INBOX 的 UIDVALIDITY，与服务器不一致说明邮箱重建过，需全量重拉。
  final int? uidValidity;

  /// 已同步到的最大 UID；下次只拉它之后的新邮件。
  final int? lastUid;

  final DateTime fetchedAt;

  Map<String, dynamic> toMap() => {
        'uid_validity': uidValidity,
        'last_uid': lastUid,
        'fetched_at': fetchedAt.toIso8601String(),
        'messages': messages.map((e) => e.toMap()).toList(),
      };

  static InboxCacheEntry fromMap(Map<dynamic, dynamic> map) => InboxCacheEntry(
        messages: (map['messages'] as List? ?? [])
            .map((e) => EmailSummary.fromMap(e as Map))
            .toList(),
        uidValidity: map['uid_validity'] as int?,
        lastUid: map['last_uid'] as int?,
        fetchedAt: DateTime.tryParse(map['fetched_at'] as String? ?? ''),
      );
}

/// 收件箱缓存存储（空间内 `inbox_cache/<accountId>.yaml`，每账号一个文件）。
/// 冷启动秒显列表与增量同步的 lastUid/UIDVALIDITY 状态都落在这里。
class InboxCacheStore {
  InboxCacheStore({String spaceId = '', Directory? dir})
      : _dir = dir ?? AppPaths.instance.inboxCacheDirFor(spaceId);

  final Directory _dir;

  File _fileFor(String accountId) => File('${_dir.path}/$accountId.yaml');

  Future<InboxCacheEntry?> load(String accountId) async {
    final map = readYamlMap(_fileFor(accountId));
    return map == null ? null : InboxCacheEntry.fromMap(map);
  }

  Future<void> save(String accountId, InboxCacheEntry entry) =>
      writeYamlFile(_fileFor(accountId), entry.toMap());

  /// 合并空间内各账号的缓存邮件，按时间倒序（冷启动展示用）。
  Future<List<EmailSummary>> loadAll(Set<String> validAccountIds) async {
    final messages = <EmailSummary>[];
    for (final id in validAccountIds) {
      final entry = await load(id);
      if (entry != null) messages.addAll(entry.messages);
    }
    messages.sort((a, b) => (b.parsedDate ?? DateTime(2000))
        .compareTo(a.parsedDate ?? DateTime(2000)));
    return messages;
  }

  /// 删除已移出空间的账号缓存文件。
  Future<void> prune(Set<String> validAccountIds) async {
    if (!_dir.existsSync()) return;
    for (final entity in _dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.yaml')) continue;
      final id = p.basenameWithoutExtension(entity.path);
      if (!validAccountIds.contains(id)) await entity.delete();
    }
  }
}

/// 合并缓存与新拉取的邮件：同账号下按 UID（无 UID 退化为 Message-ID）去重、
/// 新数据覆盖旧数据，按时间倒序后截取最近 [limit] 封。
List<EmailSummary> mergeInboxMessages(
  List<EmailSummary> cached,
  List<EmailSummary> fetched, {
  int limit = 50,
}) {
  final byKey = <String, EmailSummary>{};
  for (final m in [...cached, ...fetched]) {
    byKey[_mergeKey(m)] = m;
  }
  final merged = byKey.values.toList()
    ..sort((a, b) => (b.parsedDate ?? DateTime(2000))
        .compareTo(a.parsedDate ?? DateTime(2000)));
  return merged.length <= limit ? merged : merged.sublist(0, limit);
}

String _mergeKey(EmailSummary m) => m.uid != null
    ? '${m.accountId}:uid:${m.uid}'
    : '${m.accountId}:mid:${m.messageId}';
