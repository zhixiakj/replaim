import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 敏感信息存取抽象（便于测试注入内存实现）。
abstract class SecretStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<Map<String, String>> readAll();
}

/// flutter_secure_storage 实现。
///
/// macOS 使用 legacy keychain（usesDataProtectionKeychain: false），
/// 无需 Keychain Sharing entitlement 与 provisioning profile。
///
/// dev flavor（--flavor dev）使用独立的钥匙串 service，
/// 与正式版的密码 / API Key 条目完全隔离，互不可见、互不误删。
class SecureSecretStorage implements SecretStorage {
  SecureSecretStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            FlutterSecureStorage(
              mOptions: const MacOsOptions(
                usesDataProtectionKeychain: false,
                accountName: appFlavor == 'dev'
                    ? _devKeychainService
                    : AppleOptions.defaultAccountName,
              ),
            );

  static const _devKeychainService = 'flutter_secure_storage_service_dev';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
}

/// 测试用内存实现。
class MemorySecretStorage implements SecretStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<Map<String, String>> readAll() async => Map.of(_map);
}

/// 敏感信息按命名空间键读写：
/// - 邮箱密码：`mail_password.<accountId>`
/// - LLM API Key：`llm_api_key.<llmId>`
///
/// 旧版扁平键（mail_password / llm_api_key）仅迁移时读取，不做清理。
class SecretStore {
  SecretStore({SecretStorage? storage})
      : _storage = storage ?? SecureSecretStorage();

  static const mailPrefix = 'mail_password.';
  static const llmPrefix = 'llm_api_key.';

  /// 旧版扁平键（迁移读取）。
  static const legacyMailPasswordKey = 'mail_password';
  static const legacyLlmApiKeyKey = 'llm_api_key';

  final SecretStorage _storage;

  Future<String?> mailPassword(String accountId) =>
      _storage.read(mailPrefix + accountId);

  Future<String?> llmApiKey(String llmId) => _storage.read(llmPrefix + llmId);

  /// 空值 / null 表示删除该键。
  Future<void> saveMailPassword(String accountId, String? value) =>
      _write(mailPrefix + accountId, value);

  Future<void> saveLlmApiKey(String llmId, String? value) =>
      _write(llmPrefix + llmId, value);

  Future<void> deleteMailPassword(String accountId) =>
      _storage.delete(mailPrefix + accountId);

  Future<void> deleteLlmApiKey(String llmId) =>
      _storage.delete(llmPrefix + llmId);

  /// 一次读出全部命名空间键，返回 (邮箱密码表, LLM Key 表)。
  Future<(Map<String, String>, Map<String, String>)> loadAll() async {
    final all = await _storage.readAll();
    final mail = <String, String>{};
    final llm = <String, String>{};
    all.forEach((key, value) {
      if (key.startsWith(mailPrefix)) {
        mail[key.substring(mailPrefix.length)] = value;
      } else if (key.startsWith(llmPrefix)) {
        llm[key.substring(llmPrefix.length)] = value;
      }
    });
    return (mail, llm);
  }

  Future<String?> legacyMailPassword() =>
      _storage.read(legacyMailPasswordKey);

  Future<String?> legacyLlmApiKey() => _storage.read(legacyLlmApiKeyKey);

  Future<void> _write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key);
    } else {
      await _storage.write(key, value);
    }
  }
}
