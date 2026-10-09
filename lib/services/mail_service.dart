import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:enough_mail/enough_mail.dart' show SocketType;

import '../models/email_summary.dart';
import '../models/mail_space.dart';
import 'app_log.dart';
import 'microsoft_oauth.dart';
import 'stores.dart';

/// 邮件服务：IMAP 收件 + SMTP 发件（enough_mail 高层 API）。
///
/// 桌面端长期运行，每次操作独立连接、用完即断，避免 IMAP 空闲断连问题。
/// 每个实例对应一个邮箱账号，由调用方临时构造（推荐经
/// app_providers 的 buildMailService，它会按 authType 组装凭证）。
class MailService {
  MailService(this.config, this.password,
      {mail.OauthToken? oauthToken, this.onOAuthTokenRefreshed})
      // 公开参数名保持 oauthToken，落到私有可变字段 _oauthToken（刷新后原地更新）。
      // ignore: prefer_initializing_formals
      : _oauthToken = oauthToken;

  final MailAccountConfig config;
  final String? password;

  /// OAuth2 模式（authType == oauth）的访问令牌；密码模式为 null。
  ///
  /// 可变：微软刷新令牌时会轮转 refresh_token（旧的即刻作废），刷新成功
  /// 后更新此字段，同一实例的后续连接（如 INBOX 之后的 Sent）改用新令牌，
  /// 否则会拿已被消费的旧 refresh_token 再刷一次而 invalid_grant。
  mail.OauthToken? _oauthToken;

  mail.OauthToken? get oauthToken => _oauthToken;

  /// 令牌自动刷新成功后的持久化回调（把轮转后的新 token 写回钥匙串）。
  final Future<void> Function(mail.OauthToken token)? onOAuthTokenRefreshed;

  /// 最近一次 _connect 创建的客户端：操作超时时强制断开挂起的连接
  /// （挂起的连接可能连问候都没收到，disconnect 只能尽力而为）。
  mail.MailClient? _lastClient;

  bool get _useOAuth => config.authType == kAuthTypeOauth;

  bool get isReceiveReady =>
      config.isReceiveConfigured &&
      (_useOAuth ? oauthToken != null : (password?.isNotEmpty ?? false));

  bool get isSendReady =>
      config.isSendConfigured &&
      (_useOAuth ? oauthToken != null : (password?.isNotEmpty ?? false));

  mail.MailAccount _buildAccount() {
    final auth = _useOAuth && oauthToken != null
        ? mail.OauthAuthentication(config.email, oauthToken!)
        : mail.PlainAuthentication(config.email, password ?? '');
    return mail.MailAccount.fromManualSettingsWithAuth(
      name: config.displayName.isEmpty ? config.email : config.displayName,
      email: config.email,
      userName: config.email,
      incomingHost: config.imapHost,
      incomingPort: config.imapPort,
      incomingSocketType:
          config.imapSecure ? SocketType.ssl : SocketType.plain,
      // 纯收信账号 SMTP 可留空；enough_mail 要求非空，占位即可
      // （SMTP 懒连接，发信前另有 isSendReady 校验拦截）。
      outgoingHost:
          config.smtpHost.isEmpty ? 'smtp.unset.invalid' : config.smtpHost,
      outgoingPort: config.smtpPort,
      outgoingSocketType: _smtpSocketType(),
      auth: auth,
    );
  }

  SocketType _smtpSocketType() {
    if (!config.smtpSecure) return SocketType.plain;
    // 587 是 STARTTLS 端口，465 是隐式 SSL。
    return config.smtpPort == 587 ? SocketType.starttls : SocketType.ssl;
  }

  /// 单次 IMAP 操作（建连 + 认证 + 取信）的整体超时。
  ///
  /// enough_mail 2.1.7 的连接超时只覆盖 TCP/TLS 建连：等待服务器问候、
  /// 断线自动重连期间排队的命令都没有超时——服务器不回包时调用方会永远
  /// 挂起（收件箱无限 loading）。这里在应用层给每个操作封顶，
  /// 超时转为可展示的错误并强制断开挂起的连接。
  static const _defaultOpTimeout = Duration(seconds: 180);

  Future<T> _guarded<T>(String op, Future<T> Function() body,
      {Duration timeout = _defaultOpTimeout}) async {
    try {
      return await body().timeout(timeout);
    } on TimeoutException {
      AppLog.log('mail', '「$op」超时（${timeout.inSeconds}s）${config.email}');
      _forceDisconnectLast();
      throw MailException('「$op」超过 ${timeout.inSeconds} 秒未完成，已中止'
          '（网络不通或服务器无响应，可稍后刷新重试）');
    } on FolderNotFoundException {
      rethrow; // 调用方按「跳过已发送文件夹」分支处理
    } catch (e) {
      throw MailException(_friendlyErrorText(e));
    }
  }

  void _forceDisconnectLast() {
    final client = _lastClient;
    _lastClient = null;
    if (client == null) return;
    unawaited(client
        .disconnect()
        .timeout(const Duration(seconds: 5))
        .catchError((_) {}));
  }

  /// 把底层库 / 服务器的原始报错翻译成可操作的提示（仅 OAuth 账号追加建议）。
  String _friendlyErrorText(Object e) {
    final raw = e.toString();
    if (!_useOAuth) return raw;
    final lower = raw.toLowerCase();
    if (lower.contains('连接微软令牌服务超时')) {
      return '无法刷新 Microsoft 令牌：应用直连 login.microsoftonline.com '
          '被拦截（通常是代理/VPN 问题）。请在代理软件中切换节点或改用'
          '全局模式后重试；现在网络恢复时也会自动好转。';
    }
    if (lower.contains('unable to refresh token') ||
        lower.contains('invalid_grant')) {
      return 'Microsoft 授权已失效（$raw），请在「空间」页的账号设置里重新登录';
    }
    if ((lower.contains('authenticate') && lower.contains('fail')) ||
        lower.contains('authenticationfailed') ||
        lower.contains('invalid credentials')) {
      return '登录被服务器拒绝（$raw）。Outlook 个人账号需先在网页版开启 IMAP：'
          '设置 → 邮件 → 同步邮件 → POP 和 IMAP；企业账号请联系管理员放行 IMAP';
    }
    return raw;
  }

  Future<mail.MailClient> _connect(
      {Duration timeout = const Duration(seconds: 20)}) async {
    if (!isReceiveReady) {
      throw MailException(_useOAuth
          ? '该账号为 OAuth2 登录（Outlook），请先在账号设置里完成 Microsoft 授权'
          : '邮箱账号收信配置不完整（地址/IMAP 服务器/密码）');
    }
    if (_useOAuth && _oauthToken != null) {
      final expiry = _oauthToken!.expiresDateTime;
      final diff = DateTime.now().toUtc().difference(expiry);
      AppLog.log('mail', 'token 过期时间 ${expiry.toIso8601String()}'
          '${diff.isNegative
              ? '（${_formatDuration(-diff)}后过期）'
              : '（已过期 ${_formatDuration(diff)}）'}');
    }
    // 连接阶段超时自动重试一次：间歇性代理黑洞（TLS 完成后静默无响应）
    // 重连一次常即恢复；两次都超时才报错。
    for (var attempt = 1; attempt <= 2; attempt++) {
      // 令牌刷新前置到自己手里：enough_mail 在 connect() 内部 await 刷新
      // 回调且无超时，Dio 对 TLS 握手黑洞也无超时——挂死会拖死整个连接。
      // 刷新失败（含超时）在这里就抛带指引的错误，不进入建连。
      await _ensureFreshToken();
      try {
        return await _connectOnce(timeout, attempt);
      } on TimeoutException {
        _forceDisconnectLast();
        AppLog.log('mail', '连接阶段超时（尝试 $attempt/2）${config.email}');
      }
      if (attempt == 1) {
        AppLog.log('mail', '2 秒后重试连接 ${config.email}…');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    throw MailException('连接 ${config.imapHost}:${config.imapPort} 超时'
        '（已自动重试一次）：服务器完成 TLS 后无响应，通常是代理/VPN 节点'
        '丢包——请切换代理节点、或暂时关闭代理后重试');
  }

  /// 连接阶段（库内 token 刷新 + TCP/TLS + 等服务器问候）的整体上限。
  /// enough_mail 的 [timeout] 只覆盖 TCP/TLS 建连，等待服务器问候无超时，
  /// 服务器/代理静默无响应时会永久挂起——必须在应用层封顶。
  static const _connectPhaseTimeout = Duration(seconds: 45);

  Future<mail.MailClient> _connectOnce(Duration timeout, int attempt) async {
    // OAuth 模式：token 将在 15 分钟内过期时，enough_mail 在连接前调
    // refresh 回调换新 token（微软会轮转 refresh_token，须整体持久化）。
    final client = mail.MailClient(
      _buildAccount(),
      isLogEnabled: false,
      // 默认 5s 对高延迟服务器偏紧（LIST/SELECT 易假超时），放宽到 15s。
      defaultResponseTimeout: const Duration(seconds: 15),
      refresh: _useOAuth && _oauthToken != null ? _refreshOAuthToken : null,
    );
    // 断线 / 重连事件入日志：enough_mail 断线后会在后台无限重连并挂起
    // 排队中的命令，是收件箱卡死的头号嫌疑之一，必须留下痕迹。
    client.eventBus
        .on<mail.MailConnectionLostEvent>()
        .listen((_) => AppLog.log(
            'mail', '连接断开 ${config.email}（服务器中断或网络断开）'));
    client.eventBus
        .on<mail.MailConnectionReEstablishedEvent>()
        .listen((_) => AppLog.log('mail', '已重新连接 ${config.email}'));
    _lastClient = client;
    final sw = Stopwatch()..start();
    AppLog.log('mail', '连接 ${config.email} → ${config.imapHost}:'
        '${config.imapPort}（${_useOAuth ? 'OAuth2' : '密码'}，'
        '尝试 $attempt/2）…');
    try {
      await client.connect(timeout: timeout).timeout(_connectPhaseTimeout);
    } on TimeoutException {
      AppLog.log('mail', '连接未在 ${_connectPhaseTimeout.inSeconds}s 内完成 '
          '${config.email}（${sw.elapsedMilliseconds}ms）——'
          '卡在库内令牌刷新 / TLS / 等服务器问候之一');
      rethrow;
    } catch (e) {
      AppLog.log('mail', '连接失败 ${config.email}（${sw.elapsedMilliseconds}ms）：$e');
      rethrow;
    }
    AppLog.log('mail', '已连接 ${config.email}（${sw.elapsedMilliseconds}ms）');
    return client;
  }

  Future<mail.OauthToken> _refreshOAuthToken(
      mail.MailClient client, mail.OauthToken expired) =>
      // 兜底路径：连接存活期间令牌到期（少见）。常规刷新在 _ensureFreshToken
      // 已于连接前完成，这里不会重复触发。
      _refreshToken(expired);

  /// 刷新令牌并更新内存 + 持久化（前置刷新与 enough_mail 回调共用）。
  Future<mail.OauthToken> _refreshToken(mail.OauthToken expired) async {
    final sw = Stopwatch()..start();
    AppLog.log('mail', '刷新令牌开始 ${config.email}'
        '（当前过期时间 ${expired.expiresDateTime.toIso8601String()}）');
    // 保命超时挂在 refresh() 返回值上：refresh() 是同步函数、必然立即返回
    // Future，这里的定时器从第一微秒就被武装。Dio/HttpClient 的超时矩阵
    // 存在盲区（TCP 被 TUN 秒接、TLS 握手与更早阶段无人计时），实测坏
    // 状态下请求连 socket 都未建立就静默停滞——只有应用层最外沿的超时
    // 是绝对可靠的。
    mail.OauthToken refreshed;
    try {
      refreshed = await MicrosoftOAuth.refresh(
        clientId: config.oauthClientId,
        refreshToken: expired.refreshToken,
      ).timeout(const Duration(seconds: 22));
    } on TimeoutException {
      // 网络层故障按分钟级摆动：3 秒后重试一次，常能落回正常状态。
      AppLog.log('mail', '刷新请求停滞（22s），3 秒后重试一次 ${config.email}');
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        refreshed = await MicrosoftOAuth.refresh(
          clientId: config.oauthClientId,
          refreshToken: expired.refreshToken,
        ).timeout(const Duration(seconds: 22));
      } on TimeoutException {
        AppLog.log('mail', '刷新重试仍停滞，放弃 ${config.email}');
        throw MailException('刷新 Microsoft 令牌停滞（两轮各 22 秒均无任何进展）：'
            '应用直连 login.microsoftonline.com 被网络层拦截——'
            '请在代理软件中切换节点、改用全局模式或暂时关闭代理后重试');
      }
    }
    AppLog.log('mail', '刷新接口返回 ${config.email}'
        '（${sw.elapsedMilliseconds}ms），开始写回钥匙串…');
    // enough_mail 内部 copyWith 只换 access token，轮转后的新 refresh_token
    // 必须在这里写回钥匙串，否则下次续期仍拿旧值。
    _oauthToken = refreshed; // 本实例后续连接直接用新令牌（含新 RT）。
    final persisted = onOAuthTokenRefreshed;
    if (persisted != null) {
      try {
        // 钥匙串写入也可能挂起（平台通道无自带超时），同样封顶。
        await persisted(refreshed).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        AppLog.log('mail', '新令牌写回钥匙串超时（10s）${config.email}——'
            '本次连接继续用内存令牌');
      } catch (e) {
        // 持久化失败不阻断本次连接（内存里已有新 token）。
        AppLog.log('mail', '新令牌写回钥匙串失败 ${config.email}：$e');
      }
    }
    AppLog.log('mail', '令牌已刷新 ${config.email}（总耗时 '
        '${sw.elapsedMilliseconds}ms），'
        '新过期时间 ${refreshed.expiresDateTime.toIso8601String()}');
    return refreshed;
  }

  /// 连接前确保 OAuth token 新鲜（过期或 15 分钟内将过期时主动刷新）。
  Future<void> _ensureFreshToken() async {
    final token = _oauthToken;
    if (!_useOAuth || token == null) return;
    if (!token.willExpireIn(const Duration(minutes: 15))) return;
    try {
      await _refreshToken(token);
    } catch (e) {
      AppLog.log('mail', '令牌刷新失败 ${config.email}：$e');
      rethrow;
    }
  }

  /// 测试 IMAP 连通性，返回错误信息（null = 成功）。
  Future<String?> testConnection() => _guarded(
        '测试连接',
        () async {
          mail.MailClient? client;
          try {
            client = await _connect(timeout: const Duration(seconds: 15));
            await client.listMailboxes();
            // SMTP 在发送时才真正建连，这里只验证收信配置。
            return null;
          } on mail.MailException catch (e) {
            return _friendlyErrorText(e.message ?? e.toString());
          } catch (e) {
            return _friendlyErrorText(e);
          } finally {
            await client?.disconnect();
          }
        },
        timeout: const Duration(seconds: 150),
      );

  /// 列出服务器上的文件夹名（供学习范围配置选择）。
  Future<List<String>> listFolders() => _guarded('列出文件夹', () async {
        final client = await _connect();
        try {
          final boxes = await client.listMailboxes();
          return boxes.map((b) => b.name).toList()..sort();
        } finally {
          await client.disconnect();
        }
      });

  /// 从服务器 LIST 结果中找带 `\Sent` 特殊标记（RFC 6154）的文件夹：
  /// 服务商直接告知哪个是已发送，文件夹名随界面语言本地化也不怕
  ///（如中文 Gmail 的 `[Gmail]/已发送邮件`）。未标注或不存在返回 null。
  Future<String?> detectSentFolder() => _guarded('探测已发送文件夹', () async {
        final client = await _connect();
        try {
          final boxes = await client.listMailboxes();
          for (final b in boxes) {
            if (b.isSent) return b.name;
          }
          return null;
        } finally {
          await client.disconnect();
        }
      });

  /// 一次 LIST 同时返回全部文件夹名与 `\Sent` 标记的已发送文件夹名
  ///（供选择器标注推荐项，避免选择器连两次服务器）。
  Future<(List<String>, String?)> listFoldersWithSentFlag() =>
      _guarded('列出文件夹', () async {
        final client = await _connect();
        try {
          final boxes = await client.listMailboxes();
          String? sent;
          for (final b in boxes) {
            if (sent == null && b.isSent) sent = b.name;
          }
          return (boxes.map((b) => b.name).toList()..sort(), sent);
        } finally {
          await client.disconnect();
        }
      });

  /// 拉取最近邮件（信封 + 尽量带正文）。
  ///
  /// [folder] 为空表示 INBOX；[accountId] 标记邮件来源账号；
  /// [spaceAddresses] 为空间内全部账号地址，用于转发场景的原始收件识别。
  Future<List<EmailSummary>> fetchRecent({
    String folder = 'INBOX',
    int limit = 50,
    String accountId = '',
    Set<String> spaceAddresses = const {},
  }) =>
      _guarded('拉取 $folder', () async {
        final client = await _connect();
        try {
          final mailbox = folder == 'INBOX'
              ? await client.selectInbox()
              : await _selectByName(client, folder);
          return await _fetchSummaries(
              client, mailbox, folder, limit, accountId, spaceAddresses);
        } finally {
          await client.disconnect();
        }
      });

  /// 增量同步指定文件夹（默认 INBOX，配合 InboxCacheStore 的缓存状态）：
  /// - 无缓存 / UIDVALIDITY 与服务器不一致 → 全量拉最近 [limit] 封重建；
  /// - uidNext 显示积压新邮件超过 [limit] 封（离线太久）→ 同样走全量；
  /// - uidNext 显示没有新邮件 → 一条 FETCH 都不发，缓存原样返回；
  /// - 其余情况只 FETCH lastUid 之后的新邮件（含正文），与缓存合并去重。
  ///
  /// [folder] 为 'INBOX' 时直选收件箱；否则按名字解析真实文件夹
  /// （如 Gmail 的 '[Gmail]/Sent Mail'），结果与邮件标签都用解析后的名字。
  Future<InboxSyncResult> fetchIncremental({
    String folder = 'INBOX',
    int limit = 50,
    String accountId = '',
    Set<String> spaceAddresses = const {},
    int? cachedUidValidity,
    int? cachedLastUid,
    List<EmailSummary> cachedMessages = const [],
  }) =>
      _guarded('同步 $folder', () async {
        final sw = Stopwatch()..start();
        AppLog.log('mail', '同步 ${config.email} $folder 开始'
            '（uidValidity=${cachedUidValidity ?? '-'}，'
            'lastUid=${cachedLastUid ?? '-'}，缓存 ${cachedMessages.length} 封）');
        final client = await _connect();
        try {
          final mailbox = folder == 'INBOX'
              ? await client.selectInbox()
              : await _selectByName(client, folder);
          // INBOX 恒为 'INBOX'（与旧缓存标签一致）；其它文件夹用服务器真实名，
          // 作为缓存游标与去重键的一部分，避免与 INBOX 的 UID 撞车。
          final folderLabel = folder == 'INBOX' ? 'INBOX' : mailbox.name;
          final uidValidity = mailbox.uidValidity;
          final uidNext = mailbox.uidNext;
          AppLog.log('mail', '已选中 ${config.email} 的「$folderLabel」：'
              '共 ${mailbox.messagesExists} 封，'
              'uidValidity=$uidValidity，uidNext=$uidNext');
          final incrementalOk = uidValidity != null &&
              cachedUidValidity == uidValidity &&
              cachedLastUid != null &&
              cachedLastUid > 0 &&
              cachedMessages.isNotEmpty;
          final backlog = (uidNext == null || cachedLastUid == null)
              ? null
              : uidNext - 1 - cachedLastUid;
          final InboxSyncResult result;
          if (!incrementalOk || (backlog != null && backlog > limit)) {
            AppLog.log('mail', '走全量重建（${config.email} $folderLabel）：'
                '${!incrementalOk ? '缓存游标不可用（无缓存/UIDVALIDITY 变化）' : '积压 $backlog 封超过上限 $limit'}，'
                '拉最近 $limit 封全文…');
            final fresh = await _fetchSummaries(
                client, mailbox, folderLabel, limit, accountId, spaceAddresses);
            result = InboxSyncResult(
              messages: fresh,
              folder: folderLabel,
              uidValidity: uidValidity,
              lastUid: _maxUid(fresh) ?? cachedLastUid,
              fullResync: true,
            );
          } else if (backlog != null && backlog <= 0) {
            AppLog.log('mail', '无新邮件（${config.email} $folderLabel），'
                '缓存 ${cachedMessages.length} 封原样返回');
            result = InboxSyncResult(
              messages: cachedMessages,
              folder: folderLabel,
              uidValidity: uidValidity,
              lastUid: cachedLastUid,
            );
          } else {
            AppLog.log('mail', '增量拉取（${config.email} $folderLabel）：'
                'UID ${cachedLastUid + 1} 起 $backlog 封全文…');
            final fetched = await client.fetchMessageSequence(
              mail.MessageSequence.fromRangeToLast(cachedLastUid + 1,
                  isUidSequence: true),
              fetchPreference: mail.FetchPreference.fullWhenWithinSize,
            );
            // UID x:* 在 x 超过现存最大 UID 时仍会返回最后一封，需按 UID 过滤。
            final fresh = fetched
                .where((m) => (m.uid ?? 0) > cachedLastUid)
                .map((m) => _toSummary(m, folderLabel, accountId, spaceAddresses))
                .toList();
            final merged = mergeInboxMessages(cachedMessages, fresh, limit: limit);
            result = InboxSyncResult(
              messages: merged,
              folder: folderLabel,
              uidValidity: uidValidity,
              lastUid: _maxUid(fresh) ?? cachedLastUid,
            );
          }
          AppLog.log('mail', '同步 ${config.email} $folderLabel 完成：'
              '${result.messages.length} 封'
              '${result.fullResync ? '（全量重建）' : '（增量）'}'
              '（${sw.elapsedMilliseconds}ms）');
          return result;
        } finally {
          await client.disconnect();
        }
      });

  /// 选中文件夹后拉取最近 [limit] 封并转成应用模型。
  Future<List<EmailSummary>> _fetchSummaries(
    mail.MailClient client,
    mail.Mailbox mailbox,
    String folder,
    int limit,
    String accountId,
    Set<String> spaceAddresses,
  ) async {
    final sw = Stopwatch()..start();
    AppLog.log('mail', '开始拉取 ${config.email} $folder 最近 $limit 封全文…');
    final messages = await client.fetchMessages(
      mailbox: mailbox,
      count: limit,
      fetchPreference: mail.FetchPreference.fullWhenWithinSize,
    );
    AppLog.log('mail', '拉取完成 ${config.email} $folder：'
        '${messages.length} 封（${sw.elapsedMilliseconds}ms）');
    return messages
        .map((m) => _toSummary(m, folder, accountId, spaceAddresses))
        .toList();
  }

  Future<mail.Mailbox> _selectByName(mail.MailClient client, String name) async {
    final boxes = await client.listMailboxes();
    final names = boxes.map((b) => b.name).toList();
    final matched = matchMailboxName(names, name);
    if (matched == null) {
      throw FolderNotFoundException(_folderNotFoundMessage(name, names));
    }
    return client.selectMailbox(boxes.firstWhere((b) => b.name == matched));
  }

  /// 按文件夹与 UID 单封拉取完整邮件并转成应用模型。
  ///
  /// 详情弹窗按需补取用：老缓存邮件在模型扩展（cc / 发信认证信息）之前落盘，
  /// 增量同步只拉新 UID 不会再处理它们，这里按 UID 现拉一次补齐。
  /// 邮件在服务器上不存在返回 null；连接 / 文件夹错误向上抛，由调用方兜底。
  Future<EmailSummary?> fetchByUid({
    required String folder,
    required int uid,
    String accountId = '',
    Set<String> spaceAddresses = const {},
  }) =>
      _guarded('补取邮件详情', () async {
        final client = await _connect();
        try {
          // 选中动作本身即为目的（后续 UID FETCH 作用于当前文件夹）。
          if (folder == 'INBOX') {
            await client.selectInbox();
          } else {
            await _selectByName(client, folder);
          }
          final sequence = mail.MessageSequence(isUidSequence: true)..add(uid);
          final fetched = await client.fetchMessageSequence(
            sequence,
            fetchPreference: mail.FetchPreference.fullWhenWithinSize,
          );
          // folder 入参即缓存里存的解析后服务器名，直接作为标签保持一致。
          for (final m in fetched) {
            if (m.uid == uid) {
              return _toSummary(m, folder, accountId, spaceAddresses);
            }
          }
          return null;
        } finally {
          await client.disconnect();
        }
      });

  /// SMTP 发送纯文本回复（带 In-Reply-To 头，便于客户端线程归组）。
  ///
  /// [ccAddresses] 用于转发场景：抄送客户写信的原始收件地址
  /// （如 support@g.com），保持客户视角线程一致。
  Future<void> sendReply({
    required String toAddress,
    required String subject,
    required String inReplyToMessageId,
    required String bodyText,
    List<String> ccAddresses = const [],
  }) =>
      _guarded('发送邮件', () async {
        if (!isSendReady) {
          throw MailException(_useOAuth
              ? '该账号为 OAuth2 登录（Outlook），请先在账号设置里完成 Microsoft 授权'
              : '邮箱账号发信配置不完整（地址/SMTP 服务器/密码）');
        }
        final client = await _connect();
        try {
          final replySubject = subject.toLowerCase().startsWith('re:')
              ? subject
              : 'Re: $subject';
          final builder = mail.MessageBuilder()
            ..from = [
              mail.MailAddress(
                  config.displayName.isEmpty ? null : config.displayName,
                  config.email),
            ]
            ..to = [mail.MailAddress(null, toAddress)]
            ..subject = replySubject
            ..text = bodyText;
          if (ccAddresses.isNotEmpty) {
            builder.cc = [
              for (final a in ccAddresses)
                if (a.trim().isNotEmpty) mail.MailAddress(null, a.trim()),
            ];
          }
          builder.addHeader('in-reply-to', inReplyToMessageId);
          builder.addHeader(
              'references', inReplyToMessageId); // 简化：指向来信即可归线程
          final message = builder.buildMimeMessage();
          await client.sendMessage(message, appendToSent: true);
        } finally {
          await client.disconnect();
        }
      });

  EmailSummary _toSummary(mail.MimeMessage m, String folder, String accountId,
      Set<String> spaceAddresses) {
    final messageId = m.getHeaderValue('message-id') ??
        '<synthetic-$folder-${m.uid ?? m.guid ?? m.sequenceId ?? m.hashCode}>';
    final inReplyTo = m.getHeaderValue('in-reply-to');
    final referencesRaw = m.getHeaderValue('references') ?? '';
    final referencesIds = referencesRaw
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.startsWith('<'))
        .toList();
    final date = m.decodeDate() ?? m.envelope?.date ?? DateTime.now();
    final body = _extractBody(m);
    final toAddresses = (m.to ?? [])
        .map((a) => a.email)
        .whereType<String>()
        .toList();
    final ccAddresses = (m.cc ?? [])
        .map((a) => a.email)
        .whereType<String>()
        .toList();
    final authResults = m.getHeaderValue('authentication-results');
    return EmailSummary(
      messageId: messageId,
      subject: m.decodeSubject() ?? '（无主题）',
      fromAddress: m.from?.first.email ?? m.envelope?.from?.first.email ?? '',
      toAddresses: toAddresses,
      ccAddresses: ccAddresses,
      mailedBy: parseMailedBy(authResults),
      signedBy: parseSignedBy(authResults),
      date: date.toIso8601String(),
      folder: folder,
      bodyText: body,
      snippet: _snippet(body),
      inReplyTo: (inReplyTo != null && inReplyTo.isNotEmpty) ? inReplyTo : null,
      referencesIds: referencesIds,
      accountId: accountId,
      originalRecipients:
          detectForwardedRecipients([...toAddresses, ...ccAddresses], spaceAddresses),
      uid: m.uid,
    );
  }

  String _extractBody(mail.MimeMessage m) {
    final plain = m.decodeTextPlainPart();
    if (plain != null && plain.trim().isNotEmpty) return plain;
    final html = m.decodeTextHtmlPart();
    if (html != null) return _htmlToPlain(html);
    return '';
  }

  static String _htmlToPlain(String html) => html
      .replaceAll(RegExp(r'<(br|/p|/div|/tr)[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  String _snippet(String body) {
    final t = body.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= 120 ? t : t.substring(0, 120);
  }
}

/// 人类可读时长（token 过期状态日志用）。
String _formatDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays} 天 ${d.inHours % 24} 小时';
  if (d.inHours > 0) return '${d.inHours} 小时 ${d.inMinutes % 60} 分';
  if (d.inMinutes > 0) return '${d.inMinutes} 分 ${d.inSeconds % 60} 秒';
  return '${d.inSeconds} 秒';
}

class MailException implements Exception {
  MailException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 服务器上不存在该文件夹（message 内含现有文件夹列表提示），
/// 供调用方区分「跳过即可」与「需要报错」的失败。
class FolderNotFoundException extends MailException {
  FolderNotFoundException(super.message);
}

String _folderNotFoundMessage(String name, List<String> names) {
  final preview = names.take(10).join('、');
  final more = names.length > 10 ? ' 等共 ${names.length} 个' : '';
  return '服务器上找不到文件夹「$name」（现有：$preview$more）';
}

/// 在服务器文件夹名列表中找到与 [want] 匹配的文件夹名，找不到返回 null。
///
/// 各家服务商对同一文件夹命名不同（Gmail 是 `[Gmail]/Sent Mail`、QQ 是
/// `Sent Messages`、网易是 `已发送`），因此按三轮优先级匹配，每轮先扫完
/// 全部候选再进入下一轮（保证「精确命中」优先于「排在前面的候选」）：
/// 1. 全名大小写不敏感全等；
/// 2. 叶子名全等（按 '/' / '.' 分层取末段，兼容 '[Gmail]/Sent Mail'、
///    'INBOX.Sent' 这类层级命名）；
/// 3. 「已发送」别名组归一化匹配，让配置 Sent 能命中各家命名。
String? matchMailboxName(List<String> mailboxNames, String want) {
  final wanted = _normalizeFolderName(want);
  if (wanted.isEmpty) return null;
  for (final name in mailboxNames) {
    if (_normalizeFolderName(name) == wanted) return name;
  }
  for (final name in mailboxNames) {
    if (_leafFolderName(name) == wanted) return name;
  }
  if (!_sentFolderAliases.contains(wanted)) return null;
  for (final name in mailboxNames) {
    if (_sentFolderAliases.contains(_leafFolderName(name))) return name;
  }
  return null;
}

String _normalizeFolderName(String name) => name.trim().toLowerCase();

String _leafFolderName(String name) {
  final normalized = _normalizeFolderName(name);
  final cut = [normalized.lastIndexOf('.'), normalized.lastIndexOf('/')]
      .reduce((a, b) => a > b ? a : b);
  return cut < 0 ? normalized : normalized.substring(cut + 1);
}

/// 「已发送」文件夹在各家服务商下的常见名字（归一化后）。
/// '已发送邮件' 是中文界面 Gmail 的叶子名（`[Gmail]/已发送邮件`）。
const Set<String> _sentFolderAliases = {
  'sent',
  'sent messages',
  'sent items',
  'sent mail',
  '已发送',
  '已发邮件',
  '已发送邮件',
};

/// 从 Authentication-Results 头解析 spf=pass 的发信域名（Gmail 的 mailed-by）。
///
/// 只信收件服务器的判定（spf=pass 才取 smtp.mailfrom 域名），不回退到
/// Return-Path 等客户端可伪造的头；无该头或未通过返回空串。
String parseMailedBy(String? authResults) {
  if (authResults == null) return '';
  for (final clause in authResults.split(';')) {
    if (!clause.trim().toLowerCase().startsWith('spf=pass')) continue;
    final match = RegExp(r'smtp\.mailfrom=([^\s;)]+)').firstMatch(clause);
    if (match == null) continue;
    final value = match.group(1)!;
    return value.contains('@') ? value.split('@').last : value;
  }
  return '';
}

/// 从 Authentication-Results 头解析 dkim=pass 的签名域名（Gmail 的 signed-by）。
/// 无该头或未通过返回空串。
String parseSignedBy(String? authResults) {
  if (authResults == null) return '';
  for (final clause in authResults.split(';')) {
    if (!clause.trim().toLowerCase().startsWith('dkim=pass')) continue;
    final match = RegExp(r'header\.d=([^\s;)]+)').firstMatch(clause);
    if (match != null) return match.group(1)!;
  }
  return '';
}

/// 一次文件夹增量同步的结果。
class InboxSyncResult {
  const InboxSyncResult({
    required this.messages,
    this.folder = 'INBOX',
    this.uidValidity,
    this.lastUid,
    this.fullResync = false,
  });

  /// 合并后的全量列表（≤ limit 封）。
  final List<EmailSummary> messages;

  /// 本次同步的文件夹（解析后的服务器真实名，如 '[Gmail]/Sent Mail'）。
  final String folder;

  final int? uidValidity;
  final int? lastUid;

  /// 本次走了全量重建路径（首次同步 / UIDVALIDITY 变化 / 积压超限）。
  final bool fullResync;
}

int? _maxUid(Iterable<EmailSummary> messages) {
  int? max;
  for (final m in messages) {
    final uid = m.uid;
    if (uid != null && (max == null || uid > max)) max = uid;
  }
  return max;
}
