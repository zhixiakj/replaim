import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// YAML 读写工具：
/// - 读取：YamlMap/YamlList 递归转换为普通 Map/List；
/// - 写入：先写临时文件再原子重命名，避免写一半崩溃损坏数据文件；
/// - 多行字符串由 yaml_writer 以块标量（|-）输出，人类可读且 round-trip 无损；
/// - 字符串统一按 UTF-8 处理。
Map<String, dynamic>? readYamlMap(File file) {
  if (!file.existsSync()) return null;
  try {
    final loaded = loadYaml(file.readAsStringSync());
    if (loaded is Map) return Map<String, dynamic>.from(yamlToPlain(loaded));
    return null;
  } on YamlException {
    // 损坏的文件返回 null，由上层用默认值重建（写入侧只在成功解析后才落盘）。
    return null;
  }
}

List<Map<String, dynamic>> readYamlList(File file) {
  if (!file.existsSync()) return [];
  try {
    final loaded = loadYaml(file.readAsStringSync());
    if (loaded is List) {
      // 显式 as List 让后续链路走静态类型（dynamic 派发会丢失泛型）。
      final plain = yamlToPlain(loaded) as List;
      return plain
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  } on YamlException {
    return [];
  }
}

dynamic yamlToPlain(dynamic node) {
  if (node is Map) {
    return node.map((k, v) => MapEntry(k.toString(), yamlToPlain(v)));
  }
  if (node is List) {
    return node.map(yamlToPlain).toList();
  }
  if (node is YamlScalar) {
    return node.value;
  }
  return node;
}

Future<void> writeYamlFile(File file, dynamic data) async {
  await file.parent.create(recursive: true);
  final tmp = File('${file.path}.tmp');
  final content = YamlWriter().write(data);
  await tmp.writeAsString(content, encoding: utf8, flush: true);
  await tmp.rename(file.path);
}
