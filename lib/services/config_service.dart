import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_config.dart';
import 'paths.dart';
import 'yaml_io.dart';

/// 配置服务：非敏感配置读写 app_config.yaml，
/// 敏感项（邮箱密码/授权码、LLM API Key）走 flutter_secure_storage。
///
/// macOS 使用 legacy keychain（usesDataProtectionKeychain: false），
/// 无需 Keychain Sharing entitlement 与 provisioning profile。
class ConfigService {
  ConfigService({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  static const _kMailPassword = 'mail_password';
  static const _kLlmApiKey = 'llm_api_key';

  final FlutterSecureStorage _secure;
  File get _configFile => File(AppPaths.instance.configFile);

  Future<AppConfig> load() async {
    final map = readYamlMap(_configFile);
    if (map == null) return const AppConfig();
    return AppConfig.fromMap(map);
  }

  Future<void> save(AppConfig config) async {
    await writeYamlFile(_configFile, config.toMap());
  }

  Future<String?> loadMailPassword() => _secure.read(key: _kMailPassword);

  Future<String?> loadLlmApiKey() => _secure.read(key: _kLlmApiKey);

  Future<void> saveMailPassword(String? value) => _writeSecret(
      _kMailPassword, value);

  Future<void> saveLlmApiKey(String? value) =>
      _writeSecret(_kLlmApiKey, value);

  Future<void> _writeSecret(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _secure.delete(key: key);
    } else {
      await _secure.write(key: key, value: value);
    }
  }
}
