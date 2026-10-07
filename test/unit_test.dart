import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:replaim/models/draft_record.dart';
import 'package:replaim/models/learn_state.dart';
import 'package:replaim/models/rule.dart';
import 'package:replaim/services/feedback_learner.dart';
import 'package:replaim/services/json_extract.dart';
import 'package:replaim/services/rule_store.dart';
import 'package:replaim/services/stores.dart';
import 'package:replaim/services/yaml_io.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('replaim_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  group('yaml_io', () {
    test('Map round-trip 含中文、多行、特殊字符', () async {
      final file = File('${tmp.path}/a.yaml');
      final data = {
        'content': '退款先致歉：We are sorry for the inconvenience.',
        'multi': '第一行\nsecond line\n\n- item',
        'special': '带:冒号 #井号 "引号" \\反斜杠',
        'list': ['a', 1, true, null],
        'nested': {
          'k': 'v',
          'inner': [1, 2],
        },
      };
      await writeYamlFile(file, data);
      final back = readYamlMap(file);
      expect(back, isNotNull);
      expect(back!['content'], data['content']);
      expect(back['multi'], data['multi']);
      expect(back['special'], data['special']);
      expect(back['list'], data['list']);
      expect(back['nested'], data['nested']);
    });

    test('损坏/缺失文件返回 null 而不抛异常', () {
      final missing = File('${tmp.path}/none.yaml');
      expect(readYamlMap(missing), isNull);
      final broken = File('${tmp.path}/broken.yaml')
        ..writeAsStringSync('a: [unclosed');
      expect(readYamlMap(broken), isNull);
    });

    test('List round-trip', () async {
      final file = File('${tmp.path}/b.yaml');
      await writeYamlFile(file, [
        {'id': 1, 'v': 'a'},
        {'id': 2, 'v': '中文'},
      ]);
      final back = readYamlList(file);
      expect(back.length, 2);
      expect(back[1]['v'], '中文');
    });
  });

  group('json_extract', () {
    test('纯 JSON', () {
      expect(extractJson('[{"a":1}]'), isA<List>());
    });

    test('```json 代码块包裹', () {
      const text = '好的，以下是结果：\n```json\n[{"category":"tone"}]\n```\n以上。';
      expect(extractJsonList(text).first['category'], 'tone');
    });

    test('混在自然语言中的对象', () {
      const text = '我认为 {"change_summary": "删掉了道歉", "operations": []} 就这样';
      final data = extractJson(text) as Map;
      expect(data['change_summary'], '删掉了道歉');
    });

    test('字符串里的花括号不会干扰配平', () {
      const text = 'x {"a": "包含 } 花括号 { 的字符串"} y';
      final data = extractJson(text) as Map;
      expect(data['a'], '包含 } 花括号 { 的字符串');
    });

    test('无法解析时抛 FormatException', () {
      expect(() => extractJson('完全不是 JSON'), throwsFormatException);
    });

    test('对象包数组的兜底形态', () {
      const text = '{"rules": [{"content": "规则一"}]}';
      expect(extractJsonList(text).first['content'], '规则一');
    });

    test('readStr 支持 snake/camel 漂移', () {
      expect(readStr({'targetId': 'x'}, ['target_id', 'targetId']), 'x');
      expect(readStr({'content': ' y '}, ['content']), 'y');
    });
  });

  group('RuleStore', () {
    test('增删改 + 版本历史 round-trip', () async {
      final store = RuleStore(file: File('${tmp.path}/rules.yaml'));
      final rule = await store.addManualRule('测试规则内容', RuleCategory.tone);
      await store.updateContent(rule.id, '更新后的内容', reason: '反馈学习');
      await store.updateContent(rule.id, '再更新一次', reason: '第二次反馈');

      // 重新加载模拟重启。
      final store2 = RuleStore(file: File('${tmp.path}/rules.yaml'));
      await store2.load();
      final loaded = store2.findById(rule.id)!;
      expect(loaded.content, '再更新一次');
      expect(loaded.version, 3);
      expect(loaded.history.length, 2);
      expect(loaded.history.first.content, '测试规则内容');
      expect(loaded.history.first.reason, '反馈学习');
      expect(loaded.source.type, RuleSourceType.manual);
    });

    test('supersede 停用旧规则并保留指向', () async {
      final store = RuleStore(file: File('${tmp.path}/rules.yaml'));
      final old = await store.addManualRule('旧口径', RuleCategory.policy);
      final neu = await store.addManualRule('新口径', RuleCategory.policy);
      await store.supersede(old.id, neu.id);

      final store2 = RuleStore(file: File('${tmp.path}/rules.yaml'));
      await store2.load();
      expect(store2.findById(old.id)!.enabled, isFalse);
      expect(store2.findById(old.id)!.supersededBy, neu.id);
      expect(store2.enabledRules.length, 1);
    });

    test('来源明细（邮件 Message-ID、知识库 hash）完整保存', () async {
      final store = RuleStore(file: File('${tmp.path}/rules.yaml'));
      final rule = newRuleFromGeneration(
        type: RuleSourceType.emailHistory,
        generatedBy: 'test-model @ https://x/v1',
        details: {
          'message_ids': ['<a@b>', '<c@d>'],
          'date_range': '2026-01-01 ~ 2026-02-01',
        },
        content: '规则',
        category: RuleCategory.policy,
      );
      await store.add(rule);
      final store2 = RuleStore(file: File('${tmp.path}/rules.yaml'));
      await store2.load();
      final loaded = store2.rules.first;
      expect(loaded.source.details['message_ids'], ['<a@b>', '<c@d>']);
      expect(loaded.source.generatedBy, 'test-model @ https://x/v1');
    });

    test('deleteByKbDoc 只删对应文档规则', () async {
      final store = RuleStore(file: File('${tmp.path}/rules.yaml'));
      await store.add(newRuleFromGeneration(
        type: RuleSourceType.knowledgeBase,
        generatedBy: 'm',
        details: {'doc': 'policy.md', 'doc_hash': 'h1'},
        content: '来自 policy',
        category: RuleCategory.policy,
      ));
      await store.add(newRuleFromGeneration(
        type: RuleSourceType.knowledgeBase,
        generatedBy: 'm',
        details: {'doc': 'faq.md', 'doc_hash': 'h2'},
        content: '来自 faq',
        category: RuleCategory.policy,
      ));
      await store.addManualRule('手动规则', RuleCategory.other);
      await store.deleteByKbDoc('policy.md');

      final store2 = RuleStore(file: File('${tmp.path}/rules.yaml'));
      await store2.load();
      expect(store2.rules.length, 2);
      expect(store2.rules.any((r) =>
          r.source.type == RuleSourceType.knowledgeBase &&
          r.source.details['doc'] == 'policy.md'), isFalse);
    });

    test('stats 累加', () async {
      final store = RuleStore(file: File('${tmp.path}/rules.yaml'));
      final rule = await store.addManualRule('统计', RuleCategory.other);
      await store.markStats([rule.id], used: true, keptUnchanged: true);
      await store.markStats([rule.id], used: true);
      final store2 = RuleStore(file: File('${tmp.path}/rules.yaml'));
      await store2.load();
      expect(store2.rules.first.stats.usedCount, 2);
      expect(store2.rules.first.stats.keptUnchangedCount, 1);
    });
  });

  group('LearnStateStore', () {
    test('消费记录 round-trip + hasConsumed', () async {
      final store = LearnStateStore(file: File('${tmp.path}/learn.yaml'));
      await store.recordRun([
        ConsumedEmail(
          messageId: '<1@x>',
          date: '2026-01-01',
          subject: 'S',
          from: 'a@b.c',
          folder: 'Sent',
          learnedAt: '2026-10-07',
          generatedRuleIds: ['rule_1', 'rule_2'],
        ),
      ]);
      final store2 = LearnStateStore(file: File('${tmp.path}/learn.yaml'));
      await store2.load();
      expect(store2.state.hasConsumed('<1@x>'), isTrue);
      expect(store2.state.hasConsumed('<2@x>'), isFalse);
      expect(store2.state.consumed.first.generatedRuleIds,
          ['rule_1', 'rule_2']);
    });
  });

  group('DraftStore', () {
    test('保存/列出/查找进行中草稿', () async {
      final store = DraftStore(dir: Directory('${tmp.path}/drafts'));
      final id = store.newId();
      await store.save(DraftRecord(
        id: id,
        emailMessageId: '<msg-1>',
        subject: '退款咨询',
        toAddress: 'buyer@x.com',
        originalDraft: 'Dear customer, ...',
        usedRuleIds: const ['rule_1'],
        threadContextDigest: '',
        createdAt: DateTime.now().toIso8601String(),
        status: DraftStatus.editing,
      ));
      final editing = await store.findEditingByEmail('<msg-1>');
      expect(editing?.id, id);
      final all = await store.listAll();
      expect(all.length, 1);
      expect(all.first.originalDraft, 'Dear customer, ...');
    });
  });

  group('FeedbackLearner 静态分析', () {
    test('空白差异不算修改', () {
      const a = 'Dear,\n\nThanks.  ';
      const b = 'Dear,\n\nThanks.';
      expect(FeedbackLearner.isUnmodified(a, b), isTrue);
    });

    test('真实修改被识别', () {
      expect(
          FeedbackLearner.isUnmodified(
              'We are so sorry!', 'Thanks for reaching out!'),
          isFalse);
    });

    test('diffSummary 输出增删行', () {
      final s = FeedbackLearner.diffSummary(
          'Hello A,\nsorry.\nregards', 'Hello A,\nhere is the fix.\nregards');
      expect(s, contains('－'));
      expect(s, contains('＋'));
      expect(s, contains('sorry'));
      expect(s, contains('fix'));
    });

    test('无差异输出占位', () {
      final s = FeedbackLearner.diffSummary('same', 'same');
      expect(s, contains('无文本差异'));
    });
  });
}
