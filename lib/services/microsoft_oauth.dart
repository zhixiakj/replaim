import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:url_launcher/url_launcher.dart';

/// Microsoft（Outlook / Office 365）OAuth2 授权码 + PKCE 流程。
///
/// Microsoft 已全面禁用 IMAP/SMTP 的 Basic Auth（含应用密码），必须用
/// OAuth2 拿 access token，再经 SASL XOAUTH2 登录邮件服务器。流程：
/// 唤起系统浏览器打开授权页 → 用户登录并同意 → 微软把 code 重定向到
/// 本机回环地址（Azure 应用注册时填 `http://localhost`，运行时端口任意，
/// 微软对回环 URI 忽略端口匹配）→ 换取 access/refresh token。
///
/// 前提：用户已在 Azure 门户注册「移动和桌面应用」并拿到客户端 ID，
/// Outlook.com 个人账号还需在网页设置里开启 IMAP。
class MicrosoftOAuth {
  MicrosoftOAuth._();

  /// common 租户端点：同时支持个人 Microsoft 账号与组织（M365）账号。
  static const authorizeEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const tokenEndpoint =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';

  /// IMAP / SMTP XOAUTH2 所需的 scope；offline_access 换 refresh token。
  static const scopes =
      'openid email profile offline_access '
      'https://outlook.office.com/IMAP.AccessAsUser.All '
      'https://outlook.office.com/SMTP.Send';

  /// 等用户在浏览器里完成授权的最长时间。
  static const _authorizeTimeout = Duration(minutes: 5);

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: Headers.formUrlEncodedContentType,
  ));

  /// 按旧 refresh token 键控的在途刷新请求：同账号并发建连时只发一次。
  static final Map<String, Future<mail.OauthToken>> _refreshInFlight = {};

  /// 走浏览器完成授权并换取 token。
  ///
  /// [clientId] 是用户在 Azure 门户注册的应用（客户端）ID；
  /// [emailHint] 用于授权页预填账号（login_hint）。
  /// 失败 / 超时 / 用户取消抛 [MicrosoftOAuthException]。
  static Future<mail.OauthToken> authorize({
    required String clientId,
    String? emailHint,
  }) async {
    final random = Random.secure();
    // RFC 7636：verifier 43-128 字符，S256 challenge = BASE64URL(SHA256(verifier))。
    String b64url(List<int> bytes) =>
        base64Url.encode(bytes).replaceAll('=', '');
    final verifier =
        b64url(List<int>.generate(32, (_) => random.nextInt(256)));
    final challenge =
        b64url(sha256.convert(ascii.encode(verifier)).bytes);
    final state = b64url(List<int>.generate(16, (_) => random.nextInt(256)));

    // 回环监听：优先 IPv6 双栈（localhost 可能解析到 ::1），失败回落 IPv4。
    HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv6, 0,
          v6Only: false);
    } on SocketException {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
    final redirectUri = 'http://localhost:${server.port}';

    final authorizeUrl = Uri.parse(authorizeEndpoint).replace(queryParameters: {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'response_mode': 'query',
      'scope': scopes,
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
      if (emailHint != null && emailHint.isNotEmpty) 'login_hint': emailHint,
    });

    try {
      final opened = await launchUrl(authorizeUrl,
          mode: LaunchMode.externalApplication);
      if (!opened) {
        throw MicrosoftOAuthException(
            '无法唤起系统浏览器，请手动打开此链接完成授权：\n$authorizeUrl');
      }

      final code = await _waitForCode(server, state);
      return await _exchangeCode(
          clientId: clientId,
          code: code,
          redirectUri: redirectUri,
          verifier: verifier);
    } finally {
      await server.close(force: true);
    }
  }

  /// 等浏览器带着 code 回到回环地址；校验 state，返回 authorization code。
  static Future<String> _waitForCode(HttpServer server, String state) async {
    final request =
        await server.first.timeout(_authorizeTimeout, onTimeout: () {
      throw MicrosoftOAuthException(
          '等待浏览器授权超时（5 分钟未完成），请重试');
    });
    final params = request.uri.queryParameters;
    request.response.write(_callbackHtml(params.containsKey('code')));
    await request.response.close();

    if (params['state'] != state) {
      throw MicrosoftOAuthException('授权回调校验失败（state 不匹配），请重试');
    }
    final error = params['error'];
    if (error != null) {
      final detail = params['error_description'] ?? '';
      final friendly = error == 'access_denied' ? '你取消了授权' : '授权被拒绝：$error';
      throw MicrosoftOAuthException(
          detail.isEmpty ? friendly : '$friendly\n$detail');
    }
    final code = params['code'];
    if (code == null || code.isEmpty) {
      throw MicrosoftOAuthException('授权回调缺少 code，请重试');
    }
    return code;
  }

  /// 用授权码换 token（含 refresh token）。
  static Future<mail.OauthToken> _exchangeCode({
    required String clientId,
    required String code,
    required String redirectUri,
    required String verifier,
  }) async {
    final body = await _postToken({
      'client_id': clientId,
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'code_verifier': verifier,
      'scope': scopes,
    });
    return _parseToken(body);
  }

  /// 用 refresh token 续期。微软会轮转 refresh_token，返回的 token 里
  /// 已是新的 refresh token，调用方必须整体持久化。
  static Future<mail.OauthToken> refresh({
    required String clientId,
    required String refreshToken,
  }) {
    final inFlight = _refreshInFlight[refreshToken];
    if (inFlight != null) return inFlight;
    final future = _doRefresh(clientId: clientId, refreshToken: refreshToken)
        .whenComplete(() => _refreshInFlight.remove(refreshToken));
    _refreshInFlight[refreshToken] = future;
    return future;
  }

  static Future<mail.OauthToken> _doRefresh({
    required String clientId,
    required String refreshToken,
  }) async {
    final body = await _postToken({
      'client_id': clientId,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'scope': scopes,
    });
    // 响应偶尔不带新 refresh_token 时回落旧值（fromText 的 fallback 参数）。
    return mail.OauthToken.fromText(jsonEncode(body),
        provider: 'microsoft', refreshToken: refreshToken);
  }

  static Future<Map<String, dynamic>> _postToken(
      Map<String, String> form) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(tokenEndpoint,
          data: form);
    } catch (e) {
      throw MicrosoftOAuthException('连接微软登录服务失败：$e');
    }
    final body = response.data ?? const {};
    final error = body['error'];
    if (error != null) {
      final detail = body['error_description'] ?? '';
      throw MicrosoftOAuthException(
          '微软返回授权错误：$error${detail.isEmpty ? '' : '\n$detail'}');
    }
    return body;
  }

  static mail.OauthToken _parseToken(Map<String, dynamic> body) {
    try {
      return mail.OauthToken.fromText(jsonEncode(body),
          provider: 'microsoft');
    } catch (e) {
      throw MicrosoftOAuthException('解析微软返回的令牌失败：$e');
    }
  }

  static String _callbackHtml(bool ok) => '''
<!DOCTYPE html><html><head><meta charset="utf-8">
<title>Replaim 授权</title></head>
<body style="font-family: -apple-system, sans-serif; text-align: center; padding-top: 60px;">
<h2>${ok ? '✓ 授权成功' : '✗ 授权失败'}</h2>
<p>${ok ? '请回到 Replaim 继续操作，本页面可以关闭。' : '请回到 Replaim 查看错误原因后重试。'}</p>
</body></html>''';
}

/// OAuth 流程失败（用户取消 / 超时 / 微软返回错误等）。
class MicrosoftOAuthException implements Exception {
  MicrosoftOAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 把钥匙串里存的 token JSON 解析回 [mail.OauthToken]；损坏返回 null。
mail.OauthToken? parseOauthToken(String? json) {
  if (json == null || json.isEmpty) return null;
  try {
    return mail.OauthToken.fromJson(jsonDecode(json) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
