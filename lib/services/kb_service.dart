import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models/kb_doc.dart';
import 'paths.dart';
import 'yaml_io.dart';

/// 知识库服务：导入文档（复制进应用管理的目录）、hash 变更检测、读取内容。
///
/// 首版支持 .md / .txt（UTF-8）。
class KbService {
  KbService({Directory? dir, File? indexFile})
      : _dir = dir ?? Directory(AppPaths.instance.kbDir),
        _indexFile = indexFile ?? File(AppPaths.instance.kbIndexFile);

  final Directory _dir;
  final File _indexFile;
  static const _supportedExts = ['.md', '.txt', '.markdown'];

  Future<void> ensureDir() => _dir.create(recursive: true);

  Future<List<KbDoc>> loadIndex() async {
    final map = readYamlMap(_indexFile);
    if (map == null) return [];
    final docs = (map['docs'] as List? ?? [])
        .map((e) => KbDoc.fromMap(e as Map))
        .toList();
    return docs;
  }

  Future<void> _saveIndex(List<KbDoc> docs) =>
      writeYamlFile(_indexFile, {
        'docs': docs.map((d) => d.toMap()).toList(),
      });

  /// 导入用户选择的文件：复制到知识库目录，同名冲突时自动加序号。
  /// 返回导入后的文档清单。
  Future<List<KbDoc>> importFiles(List<String> paths) async {
    await ensureDir();
    final docs = await loadIndex();
    for (final path in paths) {
      final ext = p.extension(path).toLowerCase();
      if (!_supportedExts.contains(ext)) continue;
      final source = File(path);
      if (!source.existsSync()) continue;
      final bytes = await source.readAsBytes();
      // UTF-8 解码失败则跳过（暂不支持 GBK 等编码）。
      final text = _decodeUtf8Strict(bytes);
      if (text == null) continue;

      final base = p.basenameWithoutExtension(path);
      var fileName = p.basename(path);
      var seq = 1;
      while (docs.any((d) => d.fileName == fileName) ||
          File(p.join(_dir.path, fileName)).existsSync()) {
        fileName = '$base-${seq++}$ext';
      }
      await File(p.join(_dir.path, fileName)).writeAsString(text, flush: true);
      docs.add(KbDoc(
        fileName: fileName,
        contentHash: _hashText(text),
        importedAt: DateTime.now().toIso8601String(),
        sizeBytes: bytes.length,
        originalPath: path,
      ));
    }
    await _saveIndex(docs);
    return docs;
  }

  /// 扫描已导入文档的内容变更（重算 hash），返回 (变更文档, 最新清单)。
  Future<(List<KbDoc>, List<KbDoc>)> scanChanges() async {
    final docs = await loadIndex();
    final changed = <KbDoc>[];
    for (var i = 0; i < docs.length; i++) {
      final f = File(p.join(_dir.path, docs[i].fileName));
      if (!f.existsSync()) continue;
      final hash = _hashText(await f.readAsString());
      if (hash != docs[i].contentHash) {
        docs[i] = docs[i].copyWith(
          contentHash: hash,
          sizeBytes: f.lengthSync(),
        );
        changed.add(docs[i]);
      }
    }
    if (changed.isNotEmpty) await _saveIndex(docs);
    return (changed, docs);
  }

  /// 删除文档及其索引记录。
  Future<List<KbDoc>> removeDoc(String fileName) async {
    final docs = await loadIndex();
    final f = File(p.join(_dir.path, fileName));
    if (f.existsSync()) await f.delete();
    docs.removeWhere((d) => d.fileName == fileName);
    await _saveIndex(docs);
    return docs;
  }

  /// 读取文档全文。
  Future<String> readContent(KbDoc doc) async =>
      File(p.join(_dir.path, doc.fileName)).readAsString();

  /// 记录该文档已完成规则生成。
  Future<void> markRulesGenerated(String fileName, String hash) async {
    final docs = await loadIndex();
    final i = docs.indexWhere((d) => d.fileName == fileName);
    if (i < 0) return;
    docs[i] = docs[i].copyWith(
      ruleGeneratedHash: hash,
      ruleGeneratedAt: DateTime.now().toIso8601String(),
    );
    await _saveIndex(docs);
  }

  String? _decodeUtf8Strict(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      return null;
    }
  }

  String _hashText(String text) =>
      sha256.convert(utf8.encode(text)).toString();
}
