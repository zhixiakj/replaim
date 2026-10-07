import 'dart:io';

import '../models/app_config.dart';
import '../models/llm_profile.dart';
import 'id_gen.dart';
import 'paths.dart';
import 'yaml_io.dart';

/// 全局 LLM Profile 注册表：`llm_profiles.yaml` 的加载与变更。
/// API Key 不在此文件，走 SecretStore（`llm_api_key.<id>`）。
class LlmProfileStore {
  LlmProfileStore({File? file})
      : _file = file ?? File(AppPaths.instance.llmProfilesFile);

  final File _file;

  Future<List<LlmProfile>> loadAll() async {
    final map = readYamlMap(_file);
    if (map == null) return [];
    return (map['profiles'] as List? ?? [])
        .map((e) => LlmProfile.fromMap(e as Map))
        .toList();
  }

  Future<LlmProfile> create({required String name, LlmConfig config = const LlmConfig()}) async {
    final profile = LlmProfile(id: newLlmId(), name: name, config: config);
    await save(profile);
    return profile;
  }

  Future<void> save(LlmProfile profile) async {
    final profiles = await loadAll();
    final i = profiles.indexWhere((p) => p.id == profile.id);
    if (i >= 0) {
      profiles[i] = profile;
    } else {
      profiles.add(profile);
    }
    await _saveAll(profiles);
  }

  Future<void> delete(String id) async {
    final profiles = await loadAll();
    profiles.removeWhere((p) => p.id == id);
    await _saveAll(profiles);
  }

  Future<void> _saveAll(List<LlmProfile> profiles) =>
      writeYamlFile(_file, {
        'profiles': profiles.map((p) => p.toMap()).toList(),
      });
}
