import 'package:flutter_test/flutter_test.dart';
import 'package:replaim/services/mail_service.dart';

void main() {
  group('matchMailboxName', () {
    test('全名大小写不敏感全等', () {
      const names = ['INBOX', '[Gmail]/Sent Mail', '[Gmail]/Drafts'];
      expect(matchMailboxName(names, 'inbox'), 'INBOX');
      expect(matchMailboxName(names, '[Gmail]/Sent Mail'), '[Gmail]/Sent Mail');
      expect(matchMailboxName(names, '[gmail]/drafts'), '[Gmail]/Drafts');
    });

    test('叶子名匹配层级命名', () {
      const names = ['INBOX', 'INBOX.Sent', 'INBOX.Drafts'];
      expect(matchMailboxName(names, 'Sent'), 'INBOX.Sent');
      expect(matchMailboxName(names, 'drafts'), 'INBOX.Drafts');
    });

    test('已发送别名组：配置 Sent 命中各家命名', () {
      expect(matchMailboxName(const ['INBOX', 'Sent Messages'], 'Sent'),
          'Sent Messages');
      expect(
          matchMailboxName(const ['INBOX', 'Sent Items'], 'Sent'), 'Sent Items');
      expect(matchMailboxName(const ['INBOX', '已发送'], 'Sent'), '已发送');
      expect(matchMailboxName(const ['INBOX', '已发邮件'], 'sent'), '已发邮件');
      expect(matchMailboxName(const ['INBOX', '[Gmail]/Sent Mail'], 'Sent'),
          '[Gmail]/Sent Mail');
      // 反向：配置中文名也能命中英文命名。
      expect(matchMailboxName(const ['INBOX', 'Sent Messages'], '已发送'),
          'Sent Messages');
    });

    test('精确命中优先于排在前面的别名候选', () {
      // 若不先扫完全部候选，排在前的 'Sent Messages' 会以别名抢先命中。
      const names = ['Sent Messages', 'Sent'];
      expect(matchMailboxName(names, 'Sent'), 'Sent');
    });

    test('找不到时返回 null', () {
      expect(matchMailboxName(const ['INBOX', 'Junk'], 'Sent'), isNull);
      expect(matchMailboxName(const ['INBOX'], '  '), isNull);
      expect(matchMailboxName(const [], 'Sent'), isNull);
    });
  });
}
