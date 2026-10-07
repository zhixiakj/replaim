/// 知识库文档元信息（正文副本存放在应用数据目录的 knowledge_base/ 下）。
class KbDoc {
  const KbDoc({
    required this.fileName,
    required this.contentHash,
    required this.importedAt,
    required this.sizeBytes,
    this.originalPath = '',
    this.ruleGeneratedHash,
    this.ruleGeneratedAt,
  });

  /// 知识库目录内的文件名（唯一）。
  final String fileName;

  /// 内容 SHA-256（十六进制），用于变更检测与规则溯源。
  final String contentHash;
  final String importedAt;
  final int sizeBytes;

  /// 导入来源路径（仅记录，可能已失效）。
  final String originalPath;

  /// 已针对哪个 hash 生成过规则（null = 尚未生成）。
  final String? ruleGeneratedHash;
  final String? ruleGeneratedAt;

  bool get needsRuleGeneration => ruleGeneratedHash != contentHash;

  Map<String, dynamic> toMap() => {
        'file_name': fileName,
        'content_hash': contentHash,
        'imported_at': importedAt,
        'size_bytes': sizeBytes,
        'original_path': originalPath,
        'rule_generated_hash': ruleGeneratedHash,
        'rule_generated_at': ruleGeneratedAt,
      };

  static KbDoc fromMap(Map<dynamic, dynamic> map) => KbDoc(
        fileName: map['file_name'] as String? ?? '',
        contentHash: map['content_hash'] as String? ?? '',
        importedAt: map['imported_at'] as String? ?? '',
        sizeBytes: map['size_bytes'] as int? ?? 0,
        originalPath: map['original_path'] as String? ?? '',
        ruleGeneratedHash: map['rule_generated_hash'] as String?,
        ruleGeneratedAt: map['rule_generated_at'] as String?,
      );

  KbDoc copyWith({
    String? fileName,
    String? contentHash,
    String? importedAt,
    int? sizeBytes,
    String? originalPath,
    String? ruleGeneratedHash,
    String? ruleGeneratedAt,
  }) =>
      KbDoc(
        fileName: fileName ?? this.fileName,
        contentHash: contentHash ?? this.contentHash,
        importedAt: importedAt ?? this.importedAt,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        originalPath: originalPath ?? this.originalPath,
        ruleGeneratedHash: ruleGeneratedHash ?? this.ruleGeneratedHash,
        ruleGeneratedAt: ruleGeneratedAt ?? this.ruleGeneratedAt,
      );
}
