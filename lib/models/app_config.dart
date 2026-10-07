/// 大模型配置（OpenAI 兼容协议）。
///
/// 全局可配置多个 LLM Profile（见 `llm_profile.dart`），分配给各空间使用；
/// 非敏感字段持久化在 `llm_profiles.yaml`，API Key 存 flutter_secure_storage。
class LlmConfig {
  const LlmConfig({
    this.baseUrl = '',
    this.model = '',
    this.temperature = 0.3,
    this.maxTokens = 2048,
    this.timeoutSeconds = 120,
  });

  /// API 基础地址，通常以 /v1 结尾，例如 https://api.openai.com/v1 。
  final String baseUrl;

  /// 模型名称，例如 gpt-4o-mini、deepseek-chat 等。
  final String model;

  final double temperature;
  final int maxTokens;
  final int timeoutSeconds;

  bool get isConfigured => baseUrl.isNotEmpty && model.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'base_url': baseUrl,
        'model': model,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'timeout_seconds': timeoutSeconds,
      };

  static LlmConfig fromMap(Map<dynamic, dynamic> map) => LlmConfig(
        baseUrl: map['base_url'] as String? ?? '',
        model: map['model'] as String? ?? '',
        temperature: (map['temperature'] as num?)?.toDouble() ?? 0.3,
        maxTokens: map['max_tokens'] as int? ?? 2048,
        timeoutSeconds: map['timeout_seconds'] as int? ?? 120,
      );

  LlmConfig copyWith({
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    int? timeoutSeconds,
  }) =>
      LlmConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      );
}
