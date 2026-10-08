import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config.dart';
import '../models/conversation.dart';
import '../models/draft_record.dart';
import '../models/email_summary.dart';
import '../models/kb_doc.dart';
import '../models/learn_state.dart';
import '../models/llm_profile.dart';
import '../models/mail_space.dart';
import '../models/rule.dart';
import '../services/draft_generator.dart';
import '../services/feedback_learner.dart';
import '../services/kb_service.dart';
import '../services/llm_client.dart';
import '../services/llm_profile_store.dart';
import '../services/mail_service.dart';
import '../services/rule_generators.dart';
import '../services/rule_store.dart';
import '../services/secret_storage.dart';
import '../services/space_store.dart';
import '../services/stores.dart';

/// ------------------------------------------------------------------
/// 敏感信息（启动时一次读入内存，写操作穿透 flutter_secure_storage）
/// ------------------------------------------------------------------

class SecretsState {
  const SecretsState({
    this.mailPasswords = const {},
    this.llmApiKeys = const {},
    this.loaded = false,
  });

  /// accountId -> 邮箱密码 / 授权码。
  final Map<String, String> mailPasswords;

  /// llmProfileId -> API Key。
  final Map<String, String> llmApiKeys;

  final bool loaded;
}

class SecretsController extends Notifier<SecretsState> {
  late final SecretStore _store = SecretStore();

  /// 钥匙串加载完成的等待点；build 重建时换新，_bootstrap 完成各自持有的实例。
  Completer<void> _ready = Completer<void>();

  /// 收信 / 学习等入口在读取密码前先等待，避免冷启动拿到空表。
  Future<void> get ready => _ready.future;

  @override
  SecretsState build() {
    _ready = Completer<void>();
    _bootstrap();
    return const SecretsState();
  }

  Future<void> _bootstrap() async {
    final ready = _ready;
    try {
      // 逐键读取需要 id 清单：账号来自 space.yaml，LLM 来自 llm_profiles.yaml。
      final spaces = await SpaceStore().loadAll();
      final profiles = await LlmProfileStore().loadAll();
      final (mail, llm) = await _store.loadAll(
        accountIds: spaces.expand((s) => s.accounts).map((a) => a.id),
        llmIds: profiles.map((p) => p.id),
      );
      _set(SecretsState(mailPasswords: mail, llmApiKeys: llm, loaded: true));
    } catch (e, s) {
      // 钥匙串读取失败：按空表降级并置 loaded，避免调用方永久等待。
      debugPrint('[secrets] _bootstrap 读取钥匙串失败（按空密码处理）：$e\n$s');
      _set(const SecretsState(loaded: true));
    } finally {
      ready.complete();
    }
  }

  Future<void> saveMailPassword(String accountId, String value) async {
    await _store.saveMailPassword(accountId, value);
    _set(SecretsState(
      mailPasswords: {...state.mailPasswords, accountId: value},
      llmApiKeys: state.llmApiKeys,
      loaded: true,
    ));
  }

  Future<void> saveLlmApiKey(String llmId, String value) async {
    await _store.saveLlmApiKey(llmId, value);
    _set(SecretsState(
      mailPasswords: state.mailPasswords,
      llmApiKeys: {...state.llmApiKeys, llmId: value},
      loaded: true,
    ));
  }

  Future<void> removeAccount(String accountId) async {
    await _store.deleteMailPassword(accountId);
    _set(SecretsState(
      mailPasswords: {...state.mailPasswords}..remove(accountId),
      llmApiKeys: state.llmApiKeys,
      loaded: true,
    ));
  }

  Future<void> removeLlm(String llmId) async {
    await _store.deleteLlmApiKey(llmId);
    _set(SecretsState(
      mailPasswords: state.mailPasswords,
      llmApiKeys: {...state.llmApiKeys}..remove(llmId),
      loaded: true,
    ));
  }

  void _set(SecretsState value) {
    try {
      state = value;
    } catch (_) {
      // provider 已销毁（空间切换 / 热重载），丢弃过期的异步结果。
    }
  }
}

final secretsProvider =
    NotifierProvider<SecretsController, SecretsState>(SecretsController.new);

/// ------------------------------------------------------------------
/// 全局 LLM Profile 注册表
/// ------------------------------------------------------------------

class LlmProfilesState {
  const LlmProfilesState({this.profiles = const [], this.loaded = false});

  final List<LlmProfile> profiles;
  final bool loaded;

  LlmProfile? byId(String? id) {
    if (id == null) return null;
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class LlmProfilesController extends Notifier<LlmProfilesState> {
  late final LlmProfileStore _store = LlmProfileStore();

  @override
  LlmProfilesState build() {
    _store.loadAll().then((profiles) {
      _set(LlmProfilesState(profiles: profiles, loaded: true));
    });
    return const LlmProfilesState();
  }

  Future<LlmProfile> create(String name,
      {LlmConfig config = const LlmConfig(), String apiKey = ''}) async {
    final profile = await _store.create(name: name, config: config);
    if (apiKey.isNotEmpty) {
      await ref
          .read(secretsProvider.notifier)
          .saveLlmApiKey(profile.id, apiKey);
    }
    await _reload();
    return profile;
  }

  Future<void> save(LlmProfile profile, {String? apiKey}) async {
    await _store.save(profile);
    if (apiKey != null && apiKey.isNotEmpty) {
      await ref.read(secretsProvider.notifier).saveLlmApiKey(profile.id, apiKey);
    }
    await _reload();
  }

  Future<void> delete(String id) async {
    await _store.delete(id);
    await ref.read(secretsProvider.notifier).removeLlm(id);
    // 引用该 Profile 的空间改为未分配。
    for (final s in ref.read(spacesProvider).spaces) {
      if (s.llmProfileId == id) {
        s.llmProfileId = null;
        await ref.read(spacesProvider.notifier).save(s);
      }
    }
    await _reload();
  }

  Future<void> _reload() async {
    _set(LlmProfilesState(profiles: await _store.loadAll(), loaded: true));
  }

  void _set(LlmProfilesState value) {
    try {
      state = value;
    } catch (_) {}
  }
}

final llmProfilesProvider =
    NotifierProvider<LlmProfilesController, LlmProfilesState>(
        LlmProfilesController.new);

/// ------------------------------------------------------------------
/// 空间列表与当前空间
/// ------------------------------------------------------------------

class SpacesState {
  const SpacesState({this.spaces = const [], this.loaded = false});

  final List<MailSpace> spaces;
  final bool loaded;

  MailSpace? byId(String? id) {
    if (id == null) return null;
    for (final s in spaces) {
      if (s.id == id) return s;
    }
    return null;
  }
}

class SpacesController extends Notifier<SpacesState> {
  late final SpaceStore _store = SpaceStore();

  @override
  SpacesState build() {
    _store.loadAll().then((spaces) {
      _set(SpacesState(spaces: spaces, loaded: true));
    });
    return const SpacesState();
  }

  Future<MailSpace> create(String name) async {
    final space = await _store.create(name);
    _set(SpacesState(spaces: [...state.spaces, space], loaded: true));
    return space;
  }

  Future<void> save(MailSpace space) async {
    await _store.save(space);
    final list = [...state.spaces];
    final i = list.indexWhere((s) => s.id == space.id);
    if (i >= 0) list[i] = space;
    _set(SpacesState(spaces: list, loaded: true));
  }

  Future<void> delete(String spaceId) async {
    final space = state.byId(spaceId);
    await _store.delete(spaceId);
    for (final a in space?.accounts ?? const <MailAccountConfig>[]) {
      await ref.read(secretsProvider.notifier).removeAccount(a.id);
    }
    final list = state.spaces.where((s) => s.id != spaceId).toList();
    _set(SpacesState(spaces: list, loaded: true));
    // 删除的是当前工作空间 → 切到剩余第一个（没有则清空选择）。
    if (ref.read(spaceSelectionProvider) == spaceId) {
      await ref
          .read(spaceSelectionProvider.notifier)
          .switchTo(list.firstOrNull?.id);
    }
  }

  void _set(SpacesState value) {
    try {
      state = value;
    } catch (_) {}
  }
}

final spacesProvider =
    NotifierProvider<SpacesController, SpacesState>(SpacesController.new);

/// 当前选中的空间 ID（持久化在 app_state.yaml）。
class SpaceSelectionController extends Notifier<String?> {
  late final SpaceStore _store = SpaceStore();

  @override
  String? build() {
    _store.loadCurrentSpaceId().then(_set);
    return null;
  }

  Future<void> switchTo(String? spaceId) async {
    if (spaceId == state) return;
    await _store.saveCurrentSpaceId(spaceId);
    _set(spaceId);
  }

  void _set(String? id) {
    try {
      state = id;
    } catch (_) {}
  }
}

final spaceSelectionProvider =
    NotifierProvider<SpaceSelectionController, String?>(
        SpaceSelectionController.new);

/// 当前工作空间视图（由空间列表 + 选择组合而来）。
class CurrentSpaceState {
  const CurrentSpaceState({this.space, this.loaded = false});

  final MailSpace? space;
  final bool loaded;

  /// 按空间 ID 判等：同空间的账号 / 偏好编辑不会触发下游数据 provider 重建。
  @override
  bool operator ==(Object other) =>
      other is CurrentSpaceState &&
      other.loaded == loaded &&
      other.space?.id == space?.id;

  @override
  int get hashCode => Object.hash(space?.id, loaded);
}

final currentSpaceProvider = Provider<CurrentSpaceState>((ref) {
  final spaces = ref.watch(spacesProvider);
  final id = ref.watch(spaceSelectionProvider);
  return CurrentSpaceState(space: spaces.byId(id), loaded: spaces.loaded);
});

/// 当前空间可用的 LLM 客户端（未分配 / 未配置时为 null）。
final llmClientProvider = Provider<LlmClient?>((ref) {
  final cur = ref.watch(currentSpaceProvider);
  if (!cur.loaded) return null;
  final space = cur.space;
  if (space == null || space.llmProfileId == null) return null;
  final profile = ref.watch(llmProfilesProvider).byId(space.llmProfileId);
  if (profile == null || !profile.config.isConfigured) return null;
  final apiKey = ref.watch(secretsProvider).llmApiKeys[profile.id];
  return LlmClient(config: profile.config, apiKey: apiKey);
});

/// ------------------------------------------------------------------
/// 规则库（空间分区）
/// ------------------------------------------------------------------

class RulesState {
  const RulesState({this.rules = const [], this.loaded = false});

  final List<Rule> rules;
  final bool loaded;

  List<Rule> get enabled => rules.where((r) => r.enabled).toList();
}

class RulesController extends Notifier<RulesState> {
  RuleStore _store = RuleStore();

  RuleStore get store => _store;

  @override
  RulesState build() {
    final spaceId = ref.watch(currentSpaceProvider).space?.id ?? '';
    final store = RuleStore(spaceId: spaceId);
    _store = store;
    store.load().then((_) {
      if (!identical(_store, store)) return;
      _set(RulesState(rules: store.rules, loaded: true));
    });
    return const RulesState();
  }

  Future<void> reload() async {
    await _store.load();
    _set(RulesState(rules: _store.rules, loaded: true));
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await _store.setEnabled(id, enabled);
    await reload();
  }

  Future<void> delete(String id) async {
    await _store.delete(id);
    await reload();
  }

  Future<void> updateContent(String id, String content, String reason) async {
    await _store.updateContent(id, content,
        reason: reason.isEmpty ? '手动编辑' : reason);
    await reload();
  }

  Future<void> addManual(String content, RuleCategory category) async {
    await _store.addManualRule(content, category);
    await reload();
  }

  void _set(RulesState value) {
    try {
      state = value;
    } catch (_) {}
  }
}

final rulesProvider =
    NotifierProvider<RulesController, RulesState>(RulesController.new);

/// ------------------------------------------------------------------
/// 学习中心（历史邮件学习，多账号）
/// ------------------------------------------------------------------

class LearnRunState {
  const LearnRunState({
    this.running = false,
    this.progress = '',
    this.done = 0,
    this.total = 0,
    this.error,
    this.resultMessage,
    this.consumedCount = 0,
    this.lastRunAt,
    this.failedFolders = const [],
  });

  final bool running;
  final String progress;
  final int done;
  final int total;
  final String? error;
  final String? resultMessage;

  /// 已消费邮件总数（learn_state 统计）。
  final int consumedCount;
  final DateTime? lastRunAt;

  /// 本次运行中拉取失败的账号/文件夹及完整原因（含服务器现有文件夹列表，
  /// 供用户对照修改学习文件夹配置）。
  final List<String> failedFolders;
}

class LearnController extends Notifier<LearnRunState> {
  LearnStateStore _store = LearnStateStore();

  @override
  LearnRunState build() {
    final spaceId = ref.watch(currentSpaceProvider).space?.id ?? '';
    final store = LearnStateStore(spaceId: spaceId);
    _store = store;
    store.load().then((_) {
      if (!identical(_store, store)) return;
      final s = store.state;
      _set(LearnRunState(
        consumedCount: s.consumed.length,
        lastRunAt: s.lastRunAt,
      ));
    });
    return const LearnRunState();
  }

  LearnState get learnState => _store.state;

  /// 执行一次增量学习：只处理「未消费过 + 时间范围内」的邮件。
  /// 空间内多个账号逐一拉取历史；单账号失败不中断整体。
  Future<void> runLearning() async {
    final llm = ref.read(llmClientProvider);
    if (llm == null) {
      _set(LearnRunState(
          consumedCount: state.consumedCount,
          lastRunAt: state.lastRunAt,
          error: '请先在设置中配置大模型，并在空间中分配'));
      return;
    }
    final space = ref.read(currentSpaceProvider).space;
    if (space == null || space.accounts.isEmpty) {
      _set(LearnRunState(
          consumedCount: state.consumedCount,
          lastRunAt: state.lastRunAt,
          error: '请先在「空间」页创建空间并配置邮箱账号'));
      return;
    }
    // 冷启动竞态防护：等钥匙串密码读入内存，再筛选可用账号。
    await ref.read(secretsProvider.notifier).ready;
    final secrets = ref.read(secretsProvider);
    final usable = <MailAccountConfig>[];
    for (final a in space.accounts) {
      if (MailService(a, secrets.mailPasswords[a.id]).isReceiveReady) {
        usable.add(a);
      }
    }
    if (usable.isEmpty) {
      _set(LearnRunState(
          consumedCount: state.consumedCount,
          lastRunAt: state.lastRunAt,
          error: '空间内的邮箱账号均未配置完整（缺服务器或密码）'));
      return;
    }

    _set(LearnRunState(
        running: true,
        progress: '正在拉取历史邮件…',
        consumedCount: state.consumedCount,
        lastRunAt: state.lastRunAt));
    final failed = <String>[];
    final failedDetails = <String>[];
    try {
      final since =
          DateTime.now().subtract(Duration(days: 30 * space.learnMonths));
      final all = <EmailSummary>[];
      for (final account in usable) {
        final mail = MailService(account, secrets.mailPasswords[account.id]);
        // 发件侧（learnFolders）：既是学习材料，也是来信配对的锚点
        //（含已消费的发件——配对只认引用关系，与是否学过无关）。
        final accountSent = <EmailSummary>[];
        for (final folder in space.learnFolders) {
          _set(LearnRunState(
              running: true,
              progress:
                  '正在拉取 ${account.email} 的 $folder（近 ${space.learnMonths} 个月）…',
              consumedCount: learnState.consumed.length,
              lastRunAt: learnState.lastRunAt));
          try {
            final list = await mail.fetchRecent(
                folder: folder,
                limit: space.learnMaxPerFolder,
                accountId: account.id);
            accountSent.addAll(list);
          } catch (e) {
            failed.add('${account.email}/$folder');
            failedDetails.add('${account.email} / $folder：$e');
          }
        }
        // 收件侧：拉收件箱，只保留与发件同线程的来信（问→答配对学习）。
        _set(LearnRunState(
            running: true,
            progress: '正在拉取 ${account.email} 的 INBOX（配对客户来信）…',
            consumedCount: learnState.consumed.length,
            lastRunAt: learnState.lastRunAt));
        List<EmailSummary> accountInbox = const [];
        try {
          accountInbox = await mail.fetchRecent(
              folder: 'INBOX',
              limit: space.learnMaxPerFolder,
              accountId: account.id);
        } catch (e) {
          failed.add('${account.email}/INBOX');
          failedDetails.add('${account.email} / INBOX：$e');
        }
        final pairedInbox =
            pairIncomingWithSent(sent: accountSent, inbox: accountInbox);
        // 学习集合 = 发件 + 配对来信；仍要求时间范围内、未消费过，按 messageId 去重。
        final seen = <String>{};
        all.addAll([...accountSent, ...pairedInbox].where((e) =>
            (e.parsedDate ?? DateTime(2000)).isAfter(since) &&
            !learnState.hasConsumed(e.messageId) &&
            e.messageId.isNotEmpty &&
            seen.add(e.messageId)));
      }
      final failedNote = failed.isEmpty
          ? ''
          : '；${failed.length} 个账号/文件夹拉取失败（详见下方警告）';

      if (all.isEmpty) {
        _set(LearnRunState(
            consumedCount: learnState.consumed.length,
            lastRunAt: learnState.lastRunAt,
            failedFolders: failedDetails,
            resultMessage:
                '没有新的可学习邮件（均已消费过或超出时间范围）$failedNote'));
        return;
      }

      final generator = RuleGenerators(
          llm: llm, store: ref.read(rulesProvider.notifier).store)
        ..onProgress = (stage, done, total) {
          _set(LearnRunState(
              running: true,
              progress: stage,
              done: done,
              total: total,
              consumedCount: learnState.consumed.length,
              lastRunAt: learnState.lastRunAt));
        };
      final result = await generator.generateFromEmails(
        all,
        folders: [...space.learnFolders, 'INBOX'],
        spaceAddresses: space.accountAddresses,
      );

      // 记录已消费邮件（避免重复使用）。
      final consumed = all
          .map((e) => ConsumedEmail(
                messageId: e.messageId,
                date: e.date,
                subject: e.subject,
                from: e.fromAddress,
                folder: e.folder,
                learnedAt: DateTime.now().toIso8601String(),
                generatedRuleIds:
                    result.consumedMessageIds[e.messageId] ?? const [],
                accountId: e.accountId,
              ))
          .toList();
      await _store.recordRun(consumed);

      await ref.read(rulesProvider.notifier).reload();
      _set(LearnRunState(
        consumedCount: learnState.consumed.length,
        lastRunAt: learnState.lastRunAt,
        failedFolders: failedDetails,
        resultMessage: '学习完成：新增 ${result.addedRules.length} 条规则，'
            '更新 ${result.updatedRuleIds.toSet().length} 条，消费 ${consumed.length} 封邮件'
            '$failedNote',
      ));
    } catch (e) {
      _set(LearnRunState(
          consumedCount: learnState.consumed.length,
          lastRunAt: learnState.lastRunAt,
          failedFolders: failedDetails,
          error: '学习失败：$e'));
    }
  }

  /// 清空学习记录：下次学习会重新读取全部历史邮件（已生成的规则不受影响）。
  Future<void> resetLearning() async {
    await _store.reset();
    _set(const LearnRunState());
  }

  void _set(LearnRunState value) {
    try {
      state = value;
    } catch (_) {}
  }
}

final learnProvider =
    NotifierProvider<LearnController, LearnRunState>(LearnController.new);

/// ------------------------------------------------------------------
/// 知识库（空间分区）
/// ------------------------------------------------------------------

class KbState {
  const KbState({
    this.docs = const [],
    this.busy = false,
    this.message,
    this.error,
    this.progress = '',
  });

  final List<KbDoc> docs;
  final bool busy;
  final String? message;
  final String? error;
  final String progress;
}

class KbController extends Notifier<KbState> {
  KbService _service = KbService();

  @override
  KbState build() {
    final spaceId = ref.watch(currentSpaceProvider).space?.id ?? '';
    final service = KbService(spaceId: spaceId);
    _service = service;
    service.loadIndex().then((docs) {
      if (!identical(_service, service)) return;
      _set(KbState(docs: docs));
    });
    return const KbState();
  }

  Future<void> import(List<String> paths) async {
    state = _copy(progress: '正在导入文档…', busy: true);
    try {
      final docs = await _service.importFiles(paths);
      state = KbState(docs: docs, message: '导入完成，共 ${docs.length} 个文档');
    } catch (e) {
      state = _copy(error: '导入失败：$e');
    }
  }

  Future<void> remove(String fileName) async {
    final docs = await _service.removeDoc(fileName);
    state = KbState(docs: docs);
  }

  KbState _copy({String? progress, bool? busy, String? message, String? error}) =>
      KbState(
        docs: state.docs,
        busy: busy ?? state.busy,
        progress: progress ?? state.progress,
        message: message,
        error: error,
      );

  /// 为所有「待生成」的文档（从未生成过 / 内容已变更）重新生成规则。
  Future<void> generateRules() async {
    final llm = ref.read(llmClientProvider);
    if (llm == null) {
      state = _copy(error: '请先在设置中配置大模型，并在空间中分配');
      return;
    }
    await _service.scanChanges();
    final docs = await _service.loadIndex();
    final targets = docs.where((d) => d.needsRuleGeneration).toList();

    state = _copy(busy: true, progress: '准备生成规则…');
    final generator = RuleGenerators(
        llm: llm, store: ref.read(rulesProvider.notifier).store)
      ..onProgress = (stage, _, _) {
        state = _copy(busy: true, progress: stage);
      };
    try {
      var totalRules = 0;
      for (final doc in targets) {
        // 文档内容变更过：先移除旧规则再重新生成。
        await ref.read(rulesProvider.notifier).store.deleteByKbDoc(doc.fileName);
        final content = await _service.readContent(doc);
        final rules = await generator.generateFromKbDoc(
          docName: doc.fileName,
          docHash: doc.contentHash,
          content: content,
        );
        totalRules += rules.length;
        await _service.markRulesGenerated(doc.fileName, doc.contentHash);
      }
      await ref.read(rulesProvider.notifier).reload();
      final latest = await _service.loadIndex();
      state = KbState(
        docs: latest,
        message: targets.isEmpty
            ? '没有需要生成规则的文档'
            : '已为 ${targets.length} 个文档生成 $totalRules 条规则',
      );
    } catch (e) {
      final latest = await _service.loadIndex();
      state = KbState(docs: latest, error: '生成失败：$e');
    }
  }

  void _set(KbState value) {
    try {
      state = value;
    } catch (_) {}
  }
}

final kbProvider = NotifierProvider<KbController, KbState>(KbController.new);

/// ------------------------------------------------------------------
/// 收件箱（多账号收信合并）
/// ------------------------------------------------------------------

class InboxState {
  const InboxState({
    this.messages = const [],
    this.conversations = const [],
    this.loading = false,
    this.error,
    this.selectedKey,
    this.selectedMessage,
    this.refreshed = false,
  });

  /// 空间内全部邮件（收 + 发），按时间倒序。
  final List<EmailSummary> messages;

  /// 按「发件人 × 收件人」参与人集合汇总的会话，按最后活动时间倒序。
  final List<Conversation> conversations;

  final bool loading;
  final String? error;

  /// 选中会话的规范键（参与人集合键）。
  final String? selectedKey;

  /// 选中会话内选中的邮件（默认最新来件），生成草稿作用于它。
  final EmailSummary? selectedMessage;

  /// 本次 provider 生命周期内是否已同步过（冷启动自动刷新只触发一次）。
  final bool refreshed;

  Conversation? get selectedConversation {
    final key = selectedKey;
    if (key == null) return null;
    for (final c in conversations) {
      if (c.key == key) return c;
    }
    return null;
  }
}

class InboxController extends Notifier<InboxState> {
  InboxCacheStore _cacheStore = InboxCacheStore();

  @override
  InboxState build() {
    // 切换空间时重置收件箱（依赖 currentSpace 的空间 ID 变化）。
    final spaceId = ref.watch(currentSpaceProvider).space?.id ?? '';
    final store = InboxCacheStore(spaceId: spaceId);
    _cacheStore = store;
    final accountIds = ref
            .read(currentSpaceProvider)
            .space
            ?.receiveAccounts
            .map((a) => a.id)
            .toSet() ??
        const <String>{};
    // 先秒显缓存，后台 refresh（InboxPage 发起）再用新数据替换。
    store.loadAll(accountIds).then((cached) {
      if (!identical(_cacheStore, store)) return; // 空间已切换，丢弃过期结果。
      if (state.messages.isNotEmpty) return; // refresh 已产出更新的数据。
      _setDerived(cached);
    });
    return const InboxState();
  }

  /// 遍历空间内全部收信账号，同步 INBOX 与「已发送」两个文件夹
  /// （各自独立游标、单文件夹失败不中断），按时间倒序合并。
  ///
  /// [fullResync] 为 true 时忽略缓存全量重建（手动"完全刷新"）；
  /// 缓存超过 24 小时未全量也会自动走全量，顺带清理服务器已删邮件的残留。
  Future<void> refresh({bool fullResync = false}) async {
    final space = ref.read(currentSpaceProvider).space;
    if (space == null || space.accounts.isEmpty) {
      _setDerived(const [],
          error: '请先在「空间」页创建空间并配置邮箱账号', refreshed: true);
      return;
    }
    final receivers = space.receiveAccounts;
    if (receivers.isEmpty) {
      _setDerived(state.messages,
          error: '当前空间没有开启收信的账号', refreshed: true);
      return;
    }
    // 冷启动竞态防护：等钥匙串密码读入内存，再判断配置完整性。
    await ref.read(secretsProvider.notifier).ready;
    final secrets = ref.read(secretsProvider);
    _setDerived(state.messages, loading: true, refreshed: true);
    final addresses = space.accountAddresses;
    final store = InboxCacheStore(spaceId: space.id);
    final all = <EmailSummary>[];
    final errors = <String>[];
    for (final account in receivers) {
      final pwd = secrets.mailPasswords[account.id];
      final mail = MailService(account, pwd);
      if (!mail.isReceiveReady) {
        final reason = account.isReceiveConfigured
            ? '缺密码（钥匙串未返回该账号的授权码）'
            : '缺 IMAP 服务器配置';
        errors.add('${account.email}：配置不完整（$reason）');
        continue;
      }
      InboxCacheEntry? cached;
      try {
        cached = await store.load(account.id);
      } catch (e) {
        debugPrint('[inbox] 读缓存失败 ${account.email}：$e');
      }
      final forceFull = fullResync ||
          (cached != null &&
              DateTime.now().difference(cached.fetchedAt).inHours >= 24);
      final accountMessages = <EmailSummary>[];
      var inboxCursor = forceFull ? null : cached?.inboxCursor;
      var sentCursor = forceFull ? null : cached?.sentCursor;
      for (final role in const ['INBOX', 'Sent']) {
        final isSent = role != 'INBOX';
        final cursor = isSent ? sentCursor : inboxCursor;
        // 缓存按 folder 拆给对应文件夹（旧缓存只有 INBOX，Sent 首次走全量）。
        final cachedFolderMessages =
            (cached?.messages ?? const <EmailSummary>[])
                .where((m) =>
                    isSent ? m.folder != 'INBOX' : m.folder == 'INBOX')
                .toList();
        try {
          final result = await mail.fetchIncremental(
            folder: role,
            limit: 50,
            accountId: account.id,
            spaceAddresses: addresses,
            cachedUidValidity: forceFull ? null : cursor?.uidValidity,
            cachedLastUid: forceFull ? null : cursor?.lastUid,
            cachedMessages: forceFull ? const [] : cachedFolderMessages,
          );
          if (result.fullResync) {
            debugPrint('[inbox] ${account.email} $role'
                ' 全量同步 ${result.messages.length} 封');
          }
          accountMessages.addAll(result.messages);
          final newCursor = FolderCursor(
              uidValidity: result.uidValidity, lastUid: result.lastUid);
          if (isSent) {
            sentCursor = newCursor;
          } else {
            inboxCursor = newCursor;
          }
        } on FolderNotFoundException {
          // 服务器没有已发送文件夹（少见）：提示并跳过，不影响收件。
          if (isSent) {
            errors.add('${account.email}：未找到已发送文件夹，已跳过');
            accountMessages.addAll(cachedFolderMessages);
          }
        } catch (e) {
          // 同步失败但缓存有数据：保留缓存展示，离线不清空列表。
          if (cachedFolderMessages.isNotEmpty) {
            accountMessages.addAll(cachedFolderMessages);
            errors.add('${account.email} $role：同步失败（展示缓存）：$e');
          } else {
            errors.add('${account.email} $role：$e');
          }
        }
      }
      all.addAll(accountMessages);
      try {
        await store.save(
          account.id,
          InboxCacheEntry(
            messages: accountMessages,
            inboxCursor: inboxCursor,
            sentCursor: sentCursor,
          ),
        );
      } catch (e) {
        debugPrint('[inbox] 写缓存失败 ${account.email}：$e');
      }
    }
    all.sort((a, b) => (b.parsedDate ?? DateTime(2000))
        .compareTo(a.parsedDate ?? DateTime(2000)));
    try {
      await store.prune(receivers.map((a) => a.id).toSet());
    } catch (e) {
      debugPrint('[inbox] 清理失效缓存失败：$e');
    }
    _setDerived(all,
        error: errors.isEmpty ? null : errors.join('；'), refreshed: true);
  }

  /// 选中会话；默认选最新一封对方来件，便于直接生成草稿。
  void selectConversation(Conversation conversation) {
    _setDerived(state.messages,
        selectedKey: conversation.key, conversationSwitched: true);
  }

  /// 选中会话内某封邮件（气泡点击），生成草稿作用于它。
  void selectMessage(EmailSummary email) {
    _setDerived(state.messages, selectedMessage: email);
  }

  /// 已尝试过按需补取详情的邮件（storageKey），每封最多尝试一次，
  /// 避免弹窗反复打开时反复建连。
  final Set<String> _detailsAttempted = {};

  /// 详情弹窗按需补取：老缓存邮件缺 cc / 发信认证信息时按 UID 现拉一次。
  ///
  /// 增量同步只处理新 UID，模型扩展之前落盘的旧邮件不会再经过 _toSummary，
  /// 因此在弹窗打开时单封补取；成功后同步更新内存状态与磁盘缓存（游标不动），
  /// 下次冷启动弹窗即有完整信息。失败静默（弹窗继续展示缓存内容）。
  Future<void> ensureDetails(EmailSummary email) async {
    if (email.uid == null || !_lacksDetails(email)) return;
    final key = email.storageKey;
    if (!_detailsAttempted.add(key)) return;
    try {
      final space = ref.read(currentSpaceProvider).space;
      final account = space?.accountById(email.accountId);
      if (space == null || account == null) return;
      // await 之后 provider 可能已随空间切换销毁，后续读取都由外层 catch 兜底。
      await ref.read(secretsProvider.notifier).ready;
      final pwd = ref.read(secretsProvider).mailPasswords[account.id];
      final svc = MailService(account, pwd);
      if (!svc.isReceiveReady) return;
      final updated = await svc.fetchByUid(
        folder: email.folder,
        uid: email.uid!,
        accountId: email.accountId,
        spaceAddresses: space.accountAddresses,
      );
      if (updated == null || _lacksDetails(updated)) return;
      _setDerived([
        for (final m in state.messages)
          if (m.storageKey == key) updated else m,
      ]);
      try {
        final entry = await _cacheStore.load(updated.accountId);
        if (entry != null) {
          await _cacheStore.save(
              updated.accountId,
              InboxCacheEntry(
                messages: [
                  for (final m in entry.messages)
                    if (m.storageKey == key) updated else m,
                ],
                inboxCursor: entry.inboxCursor,
                sentCursor: entry.sentCursor,
                fetchedAt: entry.fetchedAt,
              ));
        }
      } catch (e) {
        debugPrint('[inbox] 详情回写缓存失败：$e');
      }
    } catch (_) {
      // 离线 / 服务器失败 / 空间已切换：弹窗继续展示缓存信息，不重试。
    }
  }

  /// cc 与发信认证信息全空视为缺详情（真实邮件几乎都带 Authentication-Results，
  /// 全空基本等于模型扩展之前落盘的老缓存）。
  bool _lacksDetails(EmailSummary m) =>
      m.ccAddresses.isEmpty && m.mailedBy.isEmpty && m.signedBy.isEmpty;

  /// 由邮件列表重算会话并写入状态。选中参数缺省时沿用当前选中：
  /// 刷新后会话被清掉则清空选中、选中邮件被清掉则回退当前会话最新来件，
  /// 保证刷新 / 离线兜底数据到来时选中不跳变。
  void _setDerived(
    List<EmailSummary> messages, {
    bool loading = false,
    String? error,
    bool? refreshed,
    String? selectedKey,
    bool conversationSwitched = false,
    EmailSummary? selectedMessage,
  }) {
    try {
      final space = ref.read(currentSpaceProvider).space;
      final conversations = groupConversations(
          messages, space?.accountAddresses ?? const <String>{});
      if (!conversationSwitched) selectedKey ??= state.selectedKey;
      Conversation? sel;
      for (final c in conversations) {
        if (c.key == selectedKey) {
          sel = c;
          break;
        }
      }
      if (sel == null) selectedKey = null;
      if (selectedMessage == null) {
        selectedMessage = conversationSwitched
            ? sel?.latestIncoming
            : state.selectedMessage;
        if (!conversationSwitched && selectedMessage != null) {
          // 刷新后原选中邮件可能被截断/删除，回退到当前会话最新来件。
          EmailSummary? alive;
          for (final m in messages) {
            if (m.messageId == selectedMessage.messageId) {
              alive = m;
              break;
            }
          }
          selectedMessage = alive ?? sel?.latestIncoming;
        }
      }
      state = InboxState(
        messages: messages,
        conversations: conversations,
        loading: loading,
        error: error,
        selectedKey: selectedKey,
        selectedMessage: selectedKey == null ? null : selectedMessage,
        refreshed: refreshed ?? state.refreshed,
      );
    } catch (_) {
      // provider 已随空间切换销毁，丢弃本次更新。
    }
  }
}

final inboxProvider =
    NotifierProvider<InboxController, InboxState>(InboxController.new);

/// ------------------------------------------------------------------
/// 草稿（空间分区 + 发信账号解析）
/// ------------------------------------------------------------------

class DraftsState {
  const DraftsState({
    this.records = const [],
    this.generating = false,
    this.error,
    this.message,
    this.feedbackMessage,
  });

  final List<DraftRecord> records;
  final bool generating;
  final String? error;
  final String? message;
  final String? feedbackMessage;
}

class DraftsController extends Notifier<DraftsState> {
  DraftStore _store = DraftStore();

  @override
  DraftsState build() {
    final spaceId = ref.watch(currentSpaceProvider).space?.id ?? '';
    final store = DraftStore(spaceId: spaceId);
    _store = store;
    store.listAll().then((records) {
      if (!identical(_store, store)) return;
      _set(DraftsState(records: records));
    });
    return const DraftsState();
  }

  Future<void> reload() async {
    final records = await _store.listAll();
    _set(DraftsState(
      records: records,
      feedbackMessage: state.feedbackMessage,
    ));
  }

  /// 为来信生成草稿（只用规则），返回草稿 ID。
  Future<String?> generateFor(EmailSummary email) async {
    final llm = ref.read(llmClientProvider);
    if (llm == null) {
      state = _copy(error: '请先在设置中配置大模型，并在空间中分配');
      return null;
    }
    final space = ref.read(currentSpaceProvider).space;
    if (space == null) {
      state = _copy(error: '请先创建空间');
      return null;
    }
    final existing = await _store.findEditingByEmail(email.messageId);
    if (existing != null) {
      state = _copy(message: '这封邮件已有进行中的草稿，已为你打开');
      return existing.id;
    }

    var rulesState = ref.read(rulesProvider);
    if (!rulesState.loaded) {
      // provider 可能刚随启动/切空间重建，规则尚未从磁盘载入：
      // 先等加载完成再判空，避免把「未加载」误判成「规则库为空」。
      await ref.read(rulesProvider.notifier).reload();
      rulesState = ref.read(rulesProvider);
    }
    if (rulesState.enabled.isEmpty) {
      state = _copy(
          error: rulesState.rules.isEmpty
              ? '规则库为空：草稿只能依据回复规则生成，请先在学习中心 / 知识库 / 规则库生成规则'
              : '当前规则全部处于停用状态，请先在规则库启用规则');
      return null;
    }

    state = _copy(generating: true);
    try {
      final inbox = ref.read(inboxProvider);
      // 同会话的其它往来作为线程上下文：本地缓存即有，替代原服务器
      // threadKey 拉取，且与聊天视图的参与人归组语义一致。
      final peers = <EmailSummary>[];
      for (final c in inbox.conversations) {
        if (c.messages.any((m) => m.messageId == email.messageId)) {
          peers.addAll(c.messages.where((m) => m.messageId != email.messageId));
          break;
        }
      }
      final generator = DraftGenerator(llm: llm);
      final result = await generator.generate(
        email: email,
        rules: rulesState.enabled,
        threadPeers: peers,
        outputLanguage: space.outputLanguage,
      );
      final record = DraftRecord(
        id: _store.newId(),
        emailMessageId: email.messageId,
        subject: email.subject,
        toAddress: email.fromAddress,
        originalDraft: result.draftText,
        usedRuleIds: result.usedRuleIds,
        threadContextDigest: result.threadContextDigest,
        createdAt: DateTime.now().toIso8601String(),
        status: DraftStatus.editing,
        llmGeneratedBy: llm.generatedBy,
        accountId: email.accountId,
        extraCc: email.originalRecipients,
      );
      await _store.save(record);
      await ref
          .read(rulesProvider.notifier)
          .store
          .markStats(record.usedRuleIds, used: true);
      await ref.read(rulesProvider.notifier).reload();
      await reload();
      return record.id;
    } catch (e) {
      state = _copy(error: '生成草稿失败：$e');
      return null;
    }
  }

  /// 发送草稿：解析发信账号（收信账号优先，回落默认发信账号）→ SMTP 发出
  /// （转发场景抄送原始收件地址）→ 判断是否修改 → 反馈学习。
  Future<bool> send(DraftRecord record, String finalText) async {
    final space = ref.read(currentSpaceProvider).space;
    if (space == null) {
      state = _copy(error: '请先创建空间');
      return false;
    }
    final sender = space.resolveSender(record.accountId);
    if (sender == null || !sender.isSendConfigured) {
      state = _copy(error: '当前空间没有可用于发信的账号（请在空间管理中开启账号的发信能力）');
      return false;
    }
    final pwd = ref.read(secretsProvider).mailPasswords[sender.id];
    final mail = MailService(sender, pwd);
    try {
      await mail.sendReply(
        toAddress: record.toAddress,
        subject: record.subject,
        inReplyToMessageId: record.emailMessageId,
        bodyText: finalText,
        ccAddresses: record.extraCc,
      );
    } catch (e) {
      state = _copy(error: '发送失败：$e');
      return false;
    }

    // 判断是否修改 + 反馈学习。
    var feedbackMessage = '';
    final llm = ref.read(llmClientProvider);
    final modified =
        !FeedbackLearner.isUnmodified(record.originalDraft, finalText);
    if (llm != null) {
      try {
        final learner = FeedbackLearner(
            llm: llm, store: ref.read(rulesProvider.notifier).store);
        final result =
            await learner.learn(draft: record, finalSentText: finalText);
        record
          ..finalSentText = finalText
          ..wasModified = result.wasModified
          ..diffSummary = result.diffSummary
          ..ruleUpdates = result.ruleUpdates
          ..sentAt = DateTime.now()
          ..status = result.wasModified
              ? DraftStatus.sentEdited
              : DraftStatus.sentUnmodified;
        feedbackMessage = result.wasModified
            ? '已发送。检测到修改，规则库已优化：${result.ruleUpdates.isEmpty ? "本次无需调整" : result.ruleUpdates.map((u) => "[${u.action}] ${u.summary}").join("；")}'
            : '已发送。草稿未被修改，相关规则获得正反馈';
      } catch (e) {
        record
          ..finalSentText = finalText
          ..wasModified = modified
          ..sentAt = DateTime.now()
          ..status =
              modified ? DraftStatus.sentEdited : DraftStatus.sentUnmodified;
        feedbackMessage = '已发送。但规则反馈学习失败：$e';
      }
    } else {
      record
        ..finalSentText = finalText
        ..wasModified = modified
        ..sentAt = DateTime.now()
        ..status =
            modified ? DraftStatus.sentEdited : DraftStatus.sentUnmodified;
      feedbackMessage = '已发送（未配置大模型，跳过规则反馈学习）';
    }
    await _store.save(record);
    await ref.read(rulesProvider.notifier).reload();
    state = DraftsState(feedbackMessage: feedbackMessage);
    await reload();
    return true;
  }

  Future<void> discard(DraftRecord record) async {
    record.status = DraftStatus.discarded;
    await _store.save(record);
    await reload();
  }

  DraftsState _copy({bool? generating, String? error, String? message}) =>
      DraftsState(
        records: state.records,
        generating: generating ?? state.generating,
        error: error,
        message: message,
      );

  void clearMessages() {
    state = DraftsState(records: state.records);
  }

  void _set(DraftsState value) {
    try {
      state = value;
    } catch (_) {}
  }
}

final draftsProvider =
    NotifierProvider<DraftsController, DraftsState>(DraftsController.new);
