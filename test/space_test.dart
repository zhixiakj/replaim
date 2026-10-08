import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:replaim/models/app_config.dart';
import 'package:replaim/models/draft_record.dart';
import 'package:replaim/models/learn_state.dart';
import 'package:replaim/models/mail_space.dart';
import 'package:replaim/models/rule.dart';
import 'package:replaim/services/id_gen.dart';
import 'package:replaim/services/llm_profile_store.dart';
import 'package:replaim/services/paths.dart';
import 'package:replaim/services/rule_store.dart';
import 'package:replaim/services/secret_storage.dart';
import 'package:replaim/services/space_migrator.dart';
import 'package:replaim/services/space_store.dart';
import 'package:replaim/services/yaml_io.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('replaim_space_test');
    AppPaths.forTest(tmp.path);
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  MailAccountConfig account(
    String email, {
    bool receive = true,
    bool send = true,
    String? id,
    List<String> learnFolders = const ['Sent'],
  }) =>
      MailAccountConfig(
        id: id ?? newAccountId(),
        email: email,
        imapHost: 'imap.example.com',
        smtpHost: 'smtp.example.com',
        receiveEnabled: receive,
        sendEnabled: send,
        learnFolders: learnFolders,
      );

  group('MailSpace 模型', () {
    test('round-trip：账号 / 偏好 / LLM 分配 / 默认发信', () {
      final space = MailSpace(
        id: 'space_abc',
        name: '店铺 A',
        accounts: [
          account('a@shop.com', id: 'acct_a', learnFolders: ['Sent Messages']),
          account('b@shop.com',
              receive: false,
              id: 'acct_b',
              learnFolders: ['[Gmail]/Sent Mail', 'Archive']),
        ],
        llmProfileId: 'llm_1',
        defaultSendAccountId: 'acct_a',
        outputLanguage: 'Chinese',
        learnMonths: 6,
        learnMaxPerFolder: 100,
      );
      final back = MailSpace.fromMap(space.toMap());
      expect(back.id, 'space_abc');
      expect(back.name, '店铺 A');
      expect(back.accounts.length, 2);
      expect(back.accounts[0].id, 'acct_a');
      expect(back.accounts[0].imapHost, 'imap.example.com');
      expect(back.accounts[1].receiveEnabled, isFalse);
      // 学习文件夹按账号 round-trip（多账号各不相同）。
      expect(back.accounts[0].learnFolders, ['Sent Messages']);
      expect(back.accounts[1].learnFolders, ['[Gmail]/Sent Mail', 'Archive']);
      expect(back.llmProfileId, 'llm_1');
      expect(back.defaultSendAccountId, 'acct_a');
      expect(back.outputLanguage, 'Chinese');
      expect(back.learnMonths, 6);
      expect(back.learnMaxPerFolder, 100);
    });

    test('账号 learnFolders 默认 Sent / copyWith 更新且不影响原实例', () {
      final a = MailAccountConfig(email: 'a@x.com');
      expect(a.learnFolders, ['Sent']);
      final b = a.copyWith(learnFolders: ['Sent Messages']);
      expect(b.learnFolders, ['Sent Messages']);
      expect(a.learnFolders, ['Sent']);
    });

    test('旧空间级 learn_folders 继承进各账号（账号自身键优先）', () {
      final s = MailSpace.fromMap({
        'id': 's',
        'name': 'n',
        'learn_folders': ['Legacy Folder'],
        'accounts': [
          {'id': 'acct_a', 'email': 'a@x.com'},
          {'id': 'acct_b', 'email': 'b@x.com', 'learn_folders': ['Sent Items']},
        ],
      });
      expect(s.accounts[0].learnFolders, ['Legacy Folder']);
      expect(s.accounts[1].learnFolders, ['Sent Items']);
      // 新格式不再写空间级键，账号级键保留。
      expect(s.toMap().containsKey('learn_folders'), isFalse);
      expect(s.toMap()['accounts'][1]['learn_folders'], ['Sent Items']);
    });

    test('无任何 learn_folders 键 → 账号默认 Sent', () {
      final s = MailSpace.fromMap({
        'id': 's',
        'name': 'n',
        'accounts': [
          {'id': 'acct_a', 'email': 'a@x.com'},
        ],
      });
      expect(s.accounts.single.learnFolders, ['Sent']);
    });

    test('旧格式账号 map（无 id / 收发开关）默认收 + 发', () {
      const oldMap = {
        'email': 'legacy@qq.com',
        'imap_host': 'imap.qq.com',
        'smtp_host': 'smtp.qq.com',
      };
      final a = MailAccountConfig.fromMap(oldMap);
      expect(a.id, '');
      expect(a.receiveEnabled, isTrue);
      expect(a.sendEnabled, isTrue);
      expect(a.isReceiveConfigured, isTrue);
      expect(a.isSendConfigured, isTrue);
    });

    test('receiveAccounts / sendAccounts / accountAddresses', () {
      final space = MailSpace(id: 's', name: 'n', accounts: [
        account('A@Shop.com', id: 'acct_a'),
        account('b@shop.com', receive: false, send: false, id: 'acct_b'),
      ]);
      expect(space.receiveAccounts.map((a) => a.id), ['acct_a']);
      expect(space.sendAccounts.map((a) => a.id), ['acct_a']);
      expect(space.accountAddresses, {'a@shop.com', 'b@shop.com'});
    });
  });

  group('resolveSender 发信账号解析', () {
    test('收信账号可发 → 用收信账号（线程最自然）', () {
      final space = MailSpace(id: 's', name: 'n', accounts: [
        account('a@g.com', id: 'acct_a'),
        account('b@g.com', id: 'acct_b'),
      ]);
      expect(space.resolveSender('acct_b')!.email, 'b@g.com');
    });

    test('收信账号仅收信 → 回落默认发信账号', () {
      final space = MailSpace(
        id: 's',
        name: 'n',
        accounts: [
          account('noreply@g.com', send: false, id: 'acct_in'),
          account('support@g.com', receive: false, id: 'acct_out'),
        ],
        defaultSendAccountId: 'acct_out',
      );
      expect(space.resolveSender('acct_in')!.email, 'support@g.com');
    });

    test('无默认发信账号 → 任一可发信账号', () {
      final space = MailSpace(id: 's', name: 'n', accounts: [
        account('noreply@g.com', send: false, id: 'acct_in'),
        account('support@g.com', receive: false, id: 'acct_out'),
      ]);
      expect(space.resolveSender('acct_in')!.email, 'support@g.com');
    });

    test('没有任何可发信账号 → null', () {
      final space = MailSpace(id: 's', name: 'n', accounts: [
        account('noreply@g.com', send: false, id: 'acct_in'),
      ]);
      expect(space.resolveSender('acct_in'), isNull);
      expect(space.resolveSender(null), isNull);
    });

    test('未知收信账号 ID → 按默认 / 任一可发账号处理', () {
      final space = MailSpace(id: 's', name: 'n', accounts: [
        account('support@g.com', id: 'acct_out'),
      ]);
      expect(space.resolveSender('acct_missing')!.email, 'support@g.com');
    });
  });

  group('detectForwardedRecipients 转发识别', () {
    test('正常邮件（收件人全是空间账号）→ 空', () {
      final r = detectForwardedRecipients(
        ['a@g.com', 'b@g.com'],
        {'a@g.com', 'b@g.com'},
      );
      expect(r, isEmpty);
    });

    test('转发场景：To 是未配置的 support@g.com → 识别为原始收件', () {
      final r = detectForwardedRecipients(
        ['support@g.com'],
        {'a@g.com', 'b@g.com'},
      );
      expect(r, ['support@g.com']);
    });

    test('混合收件人：空间账号被剔除，外部地址保留', () {
      final r = detectForwardedRecipients(
        ['a@g.com', 'support@g.com', 'colleague@x.com'],
        {'a@g.com', 'b@g.com'},
      );
      expect(r, ['colleague@x.com', 'support@g.com']);
    });

    test('大小写与空白归一化', () {
      final r = detectForwardedRecipients(
        [' Support@G.COM '],
        {'a@g.com'},
      );
      expect(r, ['support@g.com']);
    });
  });

  group('SpaceStore / LlmProfileStore', () {
    test('创建 / 加载 / 保存 / 删除 + 当前空间持久化', () async {
      final store = SpaceStore();
      final s1 = await store.create('空间一');
      final s2 = await store.create('空间二');
      var all = await store.loadAll();
      expect(all.map((s) => s.name), ['空间一', '空间二']);

      s1.accounts.add(account('a@x.com'));
      s1.outputLanguage = 'Chinese';
      await store.save(s1);
      all = await store.loadAll();
      expect(all.firstWhere((s) => s.id == s1.id).accounts.length, 1);
      expect(all.firstWhere((s) => s.id == s1.id).outputLanguage, 'Chinese');

      await store.saveCurrentSpaceId(s2.id);
      expect(await store.loadCurrentSpaceId(), s2.id);
      await store.saveCurrentSpaceId(null);
      expect(await store.loadCurrentSpaceId(), isNull);

      await store.delete(s1.id);
      all = await store.loadAll();
      expect(all.map((s) => s.id), [s2.id]);
      expect(Directory('${tmp.path}/spaces/${s1.id}').existsSync(), isFalse);
    });

    test('LlmProfile round-trip', () async {
      final store = LlmProfileStore();
      final p = await store.create(
        name: 'DeepSeek',
        config: const LlmConfig(
            baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat'),
      );
      p.name = '主力模型';
      await store.save(p);
      var all = await store.loadAll();
      expect(all.single.name, '主力模型');
      expect(all.single.config.model, 'deepseek-chat');

      await store.delete(p.id);
      all = await store.loadAll();
      expect(all, isEmpty);
    });
  });

  group('空间分区的数据隔离', () {
    test('RuleStore 按空间写入不同文件', () async {
      final a = RuleStore(spaceId: 'space_a');
      await a.addManualRule('空间 A 的规则', RuleCategory.policy);
      final b = RuleStore(spaceId: 'space_b');
      await b.load();
      expect(b.rules, isEmpty);
      final a2 = RuleStore(spaceId: 'space_a');
      await a2.load();
      expect(a2.rules.single.content, '空间 A 的规则');
    });
  });

  group('DraftRecord / ConsumedEmail 新字段 round-trip', () {
    test('accountId + extraCc', () {
      final r = DraftRecord(
        id: 'draft_1',
        emailMessageId: '<m>',
        subject: 's',
        toAddress: 'x@y.z',
        originalDraft: 'd',
        usedRuleIds: const [],
        threadContextDigest: '',
        createdAt: '2026-10-07',
        status: DraftStatus.editing,
        accountId: 'acct_a',
        extraCc: ['support@g.com'],
      );
      final back = DraftRecord.fromMap(r.toMap());
      expect(back.accountId, 'acct_a');
      expect(back.extraCc, ['support@g.com']);
      // 旧格式缺省。
      final old = DraftRecord.fromMap({
        'id': 'd2',
        'email_message_id': '<m2>',
        'subject': 's',
        'to_address': 'x',
        'original_draft': 'd',
        'used_rule_ids': [],
        'created_at': '2026-10-07',
        'status': 'editing',
      });
      expect(old.accountId, '');
      expect(old.extraCc, isEmpty);
    });

    test('ConsumedEmail.accountId round-trip + 旧格式缺省', () {
      const c = ConsumedEmail(
        messageId: '<1>',
        date: '2026-01-01',
        subject: 's',
        from: 'a@b.c',
        folder: 'Sent',
        learnedAt: '2026-10-07',
        generatedRuleIds: [],
        accountId: 'acct_a',
      );
      expect(ConsumedEmail.fromMap(c.toMap()).accountId, 'acct_a');
      final old = ConsumedEmail.fromMap({
        'message_id': '<2>',
        'date': '2026-01-01',
        'subject': 's',
        'from': 'a@b.c',
        'folder': 'Sent',
        'learned_at': '2026-10-07',
        'generated_rule_ids': [],
      });
      expect(old.accountId, '');
    });
  });

  group('SpaceMigrator 旧布局迁移', () {
    test('完整迁移 + 幂等', () async {
      // 构造旧布局。
      final cfg = {
        'mail': {
          'email': 'a@g.com',
          'display_name': 'Amy',
          'imap_host': 'imap.g.com',
          'imap_port': 993,
          'imap_secure': true,
          'smtp_host': 'smtp.g.com',
          'smtp_port': 465,
          'smtp_secure': true,
        },
        'llm': {
          'base_url': 'https://api.deepseek.com/v1',
          'model': 'deepseek-chat',
          'temperature': 0.3,
          'max_tokens': 2048,
          'timeout_seconds': 120,
        },
        'output_language': 'English',
        'learn_folders': ['Sent Messages'],
        'learn_months': 6,
        'learn_max_per_folder': 100,
      };
      await writeYamlFile(File('${tmp.path}/config/app_config.yaml'), cfg);
      await writeYamlFile(File('${tmp.path}/rules/rules.yaml'), [
        {'id': 'rule_1', 'content': '旧规则', 'category': 'policy'}
      ]);
      await writeYamlFile(File('${tmp.path}/learn_state.yaml'), {
        'consumed': [
          {
            'message_id': '<1@x>',
            'date': '2026-01-01',
            'subject': 'S',
            'from': 'a@b.c',
            'folder': 'Sent',
            'learned_at': '2026-10-01',
            'generated_rule_ids': ['rule_1'],
          }
        ],
        'last_run_at': null,
      });
      Directory('${tmp.path}/knowledge_base').createSync(recursive: true);
      File('${tmp.path}/knowledge_base/faq.md').writeAsStringSync('# FAQ');
      Directory('${tmp.path}/drafts').createSync(recursive: true);
      await writeYamlFile(File('${tmp.path}/drafts/draft_old.yaml'), {
        'id': 'draft_old',
        'email_message_id': '<m>',
        'subject': 's',
        'to_address': 'x@y.z',
        'original_draft': 'd',
        'used_rule_ids': [],
        'created_at': '2026-10-01',
        'status': 'editing',
      });

      // 旧扁平 secrets。
      final memStorage = MemorySecretStorage();
      await memStorage.write('mail_password', 'legacy-mail-pwd');
      await memStorage.write('llm_api_key', 'legacy-llm-key');
      final secrets = SecretStore(storage: memStorage);

      final migrator = SpaceMigrator(
        spaceStore: SpaceStore(),
        llmStore: LlmProfileStore(),
        secrets: secrets,
      );
      expect(await migrator.migrateIfNeeded(), isTrue);

      // 空间与账号。
      final spaces = await SpaceStore().loadAll();
      expect(spaces.length, 1);
      final space = spaces.single;
      expect(space.name, '默认空间');
      expect(space.accounts.single.email, 'a@g.com');
      expect(space.accounts.single.receiveEnabled, isTrue);
      expect(space.accounts.single.sendEnabled, isTrue);
      expect(space.accounts.single.id, isNotEmpty);
      // 学习文件夹并入首个账号（现按账号配置）。
      expect(space.accounts.single.learnFolders, ['Sent Messages']);
      expect(space.learnMonths, 6);
      expect(space.learnMaxPerFolder, 100);
      expect(space.outputLanguage, 'English');

      // LLM Profile。
      final profiles = await LlmProfileStore().loadAll();
      expect(profiles.single.config.model, 'deepseek-chat');
      expect(space.llmProfileId, profiles.single.id);

      // secrets 复制到命名空间键，旧键保留。
      expect(await secrets.mailPassword(space.accounts.single.id),
          'legacy-mail-pwd');
      expect(await secrets.llmApiKey(profiles.single.id), 'legacy-llm-key');
      expect(await secrets.legacyMailPassword(), 'legacy-mail-pwd');

      // 数据文件搬入空间目录。
      final spaceRoot = '${tmp.path}/spaces/${space.id}';
      expect(File('$spaceRoot/rules/rules.yaml').existsSync(), isTrue);
      expect(File('$spaceRoot/knowledge_base/faq.md').existsSync(), isTrue);
      expect(File('$spaceRoot/learn_state.yaml').existsSync(), isTrue);
      expect(File('$spaceRoot/drafts/draft_old.yaml').existsSync(), isTrue);
      expect(File('${tmp.path}/rules/rules.yaml').existsSync(), isFalse);
      expect(File('${tmp.path}/learn_state.yaml').existsSync(), isFalse);
      expect(File('${tmp.path}/config/app_config.yaml').existsSync(), isFalse);

      // 当前空间指向默认空间。
      expect(await SpaceStore().loadCurrentSpaceId(), space.id);

      // 幂等：再次运行不做任何事。
      expect(await migrator.migrateIfNeeded(), isFalse);
    });

    test('全新安装（无旧文件）不迁移', () async {
      final migrator = SpaceMigrator(
        spaceStore: SpaceStore(),
        llmStore: LlmProfileStore(),
        secrets: SecretStore(storage: MemorySecretStorage()),
      );
      expect(await migrator.migrateIfNeeded(), isFalse);
      expect(await SpaceStore().loadAll(), isEmpty);
    });

    test('空 config 但有规则文件也迁移（无账号无 LLM）', () async {
      await writeYamlFile(File('${tmp.path}/rules/rules.yaml'), [
        {'id': 'rule_1', 'content': '旧规则', 'category': 'policy'}
      ]);
      final migrator = SpaceMigrator(
        spaceStore: SpaceStore(),
        llmStore: LlmProfileStore(),
        secrets: SecretStore(storage: MemorySecretStorage()),
      );
      expect(await migrator.migrateIfNeeded(), isTrue);
      final space = (await SpaceStore().loadAll()).single;
      expect(space.accounts, isEmpty);
      expect(space.llmProfileId, isNull);
      expect(File('${tmp.path}/spaces/${space.id}/rules/rules.yaml')
          .existsSync(), isTrue);
    });
  });
}
