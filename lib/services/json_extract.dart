import 'dart:convert';

/// 从 LLM 输出中容错提取 JSON。
///
/// 兼容三种常见输出形态：
/// 1. 纯 JSON；
/// 2. ```json ... ``` 代码块（前后带说明文字）；
/// 3. 混在自然语言里的首尾大括号/中括号片段。
dynamic extractJson(String text) {
  final cleaned = _stripCodeFence(text);
  final obj = _findBracketed(cleaned, '{');
  final arr = _findBracketed(cleaned, '[');
  final candidates = [cleaned.trim(), ?obj, ?arr];
  for (final c in candidates) {
    if (c.isEmpty) continue;
    try {
      return jsonDecode(c);
    } on FormatException {
      continue;
    }
  }
  throw FormatException('无法从模型输出中解析 JSON');
}

String _stripCodeFence(String text) {
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
  final m = fence.firstMatch(text);
  return m != null ? m.group(1)! : text;
}

/// 提取第一个配平的 {...} 或 [...] 片段（忽略字符串字面量内的括号）。
String? _findBracketed(String text, String open) {
  final close = open == '{' ? '}' : ']';
  final start = text.indexOf(open);
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < text.length; i++) {
    final ch = text[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch == r'\' && inString) {
      escaped = true;
      continue;
    }
    if (ch == '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (ch == open) {
      depth++;
    } else if (ch == close) {
      depth--;
      if (depth == 0) return text.substring(start, i + 1);
    }
  }
  return null;
}

/// 期望 List<Map> 时使用；元素不是 Map 的条目被丢弃。
List<Map<String, dynamic>> extractJsonList(String text) {
  final data = extractJson(text);
  if (data is List) {
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (data is Map && data.values.whereType<List>().isNotEmpty) {
    // 模型偶尔输出 {"rules": [...]} 形态，取第一个 List 值。
    final list = data.values.firstWhere((v) => v is List) as List;
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  throw FormatException('模型输出不是 JSON 数组');
}

/// 安全读取字段：模型字段名经常在 snake/camel 之间漂移。
String? readStr(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  return null;
}
