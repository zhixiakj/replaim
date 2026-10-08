import 'package:flutter_test/flutter_test.dart';
import 'package:replaim/services/mail_provider_presets.dart';

void main() {
  group('mailProviderPresetFor 服务商预设', () {
    test('常见域名命中：服务器地址与已发送文件夹', () {
      final gmail = mailProviderPresetFor('User@GMAIL.com')!;
      expect(gmail.imapHost, 'imap.gmail.com');
      expect(gmail.imapPort, 993);
      expect(gmail.smtpHost, 'smtp.gmail.com');
      expect(gmail.smtpPort, 465);
      // Gmail 文件夹名随界面语言本地化，中英文都预置。
      expect(gmail.sentFolders, contains('[Gmail]/Sent Mail'));
      expect(gmail.sentFolders, contains('[Gmail]/已发送邮件'));

      final qq = mailProviderPresetFor('12345@qq.com')!;
      expect(qq.imapHost, 'imap.qq.com');
      expect(qq.sentFolders, ['Sent Messages']);

      // Foxmail 与 QQ 同一组服务器。
      expect(mailProviderPresetFor('a@foxmail.com')!.imapHost, 'imap.qq.com');

      final outlook = mailProviderPresetFor('a@hotmail.com')!;
      expect(outlook.imapHost, 'outlook.office365.com');
      expect(outlook.smtpHost, 'smtp.office365.com');
      expect(outlook.smtpPort, 587); // STARTTLS

      expect(mailProviderPresetFor('a@163.com')!.imapHost, 'imap.163.com');
      expect(mailProviderPresetFor('a@126.com')!.imapHost, 'imap.126.com');
      expect(mailProviderPresetFor('a@yeah.net')!.imapHost, 'imap.yeah.net');
      expect(mailProviderPresetFor('a@icloud.com')!.imapHost, 'imap.mail.me.com');
      expect(mailProviderPresetFor('a@yahoo.com')!.sentFolders, ['Sent']);
    });

    test('未知域名 / 非法输入 → null', () {
      expect(mailProviderPresetFor('a@unknown-provider.net'), isNull);
      expect(mailProviderPresetFor('no-at-sign'), isNull);
      expect(mailProviderPresetFor(''), isNull);
      expect(mailProviderPresetFor('@'), isNull);
    });
  });
}
