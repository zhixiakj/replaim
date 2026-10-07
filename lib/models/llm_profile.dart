import 'app_config.dart';

/// 全局 LLM Profile：应用可配置多个大模型端点，分配给各空间使用。
///
/// 非敏感字段持久化在 `llm_profiles.yaml`；
/// API Key 按 `llm_api_key.<profileId>` 存放于 flutter_secure_storage。
class LlmProfile {
  LlmProfile({
    required this.id,
    required this.name,
    this.config = const LlmConfig(),
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;

  /// 显示名，例如「DeepSeek」「公司 GPT」。
  String name;

  /// OpenAI 兼容端点配置（可变：编辑后整体落盘）。
  LlmConfig config;

  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'config': config.toMap(),
        'created_at': createdAt.toIso8601String(),
      };

  static LlmProfile fromMap(Map<dynamic, dynamic> map) => LlmProfile(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '未命名模型',
        config: LlmConfig.fromMap(map['config'] ?? {}),
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      );
}
