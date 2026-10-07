import 'dart:async';

import 'package:dio/dio.dart';

import '../models/app_config.dart';
import 'json_extract.dart';

class LlmMessage {
  const LlmMessage.role(this.role, this.content);

  const LlmMessage.system(String content) : this.role('system', content);

  const LlmMessage.user(String content) : this.role('user', content);

  const LlmMessage.assistant(String content) : this.role('assistant', content);

  final String role;
  final String content;

  Map<String, dynamic> toMap() => {'role': role, 'content': content};
}

class LlmResult {
  const LlmResult({required this.content, required this.model, this.promptTokens, this.completionTokens});

  final String content;
  final String model;
  final int? promptTokens;
  final int? completionTokens;
}

/// OpenAI 兼容 /chat/completions 客户端。
///
/// 用户可自定义 base URL / 模型名 / API Key，兼容 OpenAI、DeepSeek、
/// Moonshot、本地 Ollama 等一切兼容端点。
class LlmClient {
  LlmClient({
    required this.config,
    required this.apiKey,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: Duration(seconds: config.timeoutSeconds),
              receiveTimeout: Duration(seconds: config.timeoutSeconds),
              validateStatus: (code) => true, // 状态码交给调用方判断
            ));

  final LlmConfig config;
  final String? apiKey;
  final Dio _dio;

  String get generatedBy => '${config.model} @ ${config.baseUrl}';

  String get endpoint {
    var base = config.baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return '$base/chat/completions';
  }

  bool get isConfigured => config.isConfigured;

  /// 普通对话，返回模型文本。
  Future<LlmResult> chat(
    List<LlmMessage> messages, {
    double? temperature,
    int? maxTokens,
  }) async {
    final body = <String, dynamic>{
      'model': config.model,
      'messages': messages.map((m) => m.toMap()).toList(),
      'temperature': temperature ?? config.temperature,
      'max_tokens': ?maxTokens,
    };
    final data = await _post(body);
    final content =
        _firstChoice(data) ?? (throw LlmException('模型未返回任何内容'));
    return LlmResult(
      content: content,
      model: (data['model'] as String?) ?? config.model,
      promptTokens: _usage(data, 'prompt_tokens'),
      completionTokens: _usage(data, 'completion_tokens'),
    );
  }

  /// 要求 JSON 输出并容错解析，失败自动重试（最多 [retries] 次）。
  Future<dynamic> chatJson(
    List<LlmMessage> messages, {
    double? temperature,
    int? maxTokens,
    int retries = 2,
  }) async {
    Object? lastError;
    var attemptMessages = [...messages];
    for (var attempt = 0; attempt <= retries; attempt++) {
      final result = await chat(
        attemptMessages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      try {
        return extractJson(result.content);
      } on FormatException catch (e) {
        lastError = e;
        attemptMessages = [
          ...messages,
          LlmMessage.assistant(result.content),
          const LlmMessage.user('输出不是合法 JSON。请重新回答，只输出 JSON 本身，不要任何其他文字。'),
        ];
      }
    }
    throw LlmException('模型多次未能输出合法 JSON：$lastError');
  }

  /// 连接测试：发一条极小的请求验证 base URL / key / 模型名。
  /// 返回错误信息（null = 成功）。404 时自动尝试补 /v1 重试一次。
  Future<String?> testConnection() async {
    if (!isConfigured) return '请先填写 Base URL 和模型名';
    String? error = await _testOnce(endpoint);
    if (error != null && error.contains('404')) {
      final fallback = _endpointWithV1();
      if (fallback != null) {
        error = await _testOnce(fallback);
        if (error == null) {
          return null; // 期望调用方随后把 base 改为补 /v1 的形式
        }
      }
    }
    return error;
  }

  /// testConnection 探测出的可用 endpoint（若自动补了 /v1）。
  String? probedEndpoint;

  String? _endpointWithV1() {
    var base = config.baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.endsWith('/v1') || base.endsWith('/v2')) return null;
    return '$base/v1/chat/completions';
  }

  Future<String?> _testOnce(String url) async {
    try {
      final response = await _dio.post<dynamic>(
        url,
        options: Options(headers: _headers()),
        data: {
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
          'max_tokens': 8,
        },
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        probedEndpoint = url;
        return null;
      }
      return 'HTTP $status：${_errorDetail(response.data)}';
    } on DioException catch (e) {
      return e.message ?? '网络错误';
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        options: Options(headers: _headers()),
        data: body,
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw LlmException('HTTP $status：${_errorDetail(response.data)}');
      }
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw LlmException('请求超时（${config.timeoutSeconds}s），可在设置中调大超时');
      }
      throw LlmException(e.message ?? '网络错误');
    }
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty)
          'Authorization': 'Bearer ${apiKey!}',
      };

  static String? _firstChoice(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final choice = choices.first;
      if (choice is Map) {
        final message = choice['message'];
        if (message is Map) return message['content'] as String?;
      }
    }
    return null;
  }

  static int? _usage(Map<String, dynamic> data, String key) {
    final usage = data['usage'];
    if (usage is Map) return usage[key] as int?;
    return null;
  }

  static String _errorDetail(dynamic data) {
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        final msg = err['message'];
        if (msg != null) return msg.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return data?.toString() ?? '未知错误';
  }
}

class LlmException implements Exception {
  LlmException(this.message);

  final String message;

  @override
  String toString() => message;
}
