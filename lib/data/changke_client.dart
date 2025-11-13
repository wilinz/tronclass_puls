import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:tronclass/data/get_storage.dart';
import 'package:tronclass/data/service/tronclass.dart';
import 'package:tronclass/http/proxy/setup_http_proxy.dart';
import 'package:tronclass/path.dart';

typedef CaptchaRequester = Future<String> Function(Uint8List image);

class ChangkeClient {
  ChangkeClient._();

  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 micromessenger';

  // 多用户实例管理
  static final Map<String, ChangkeClient> _instances = {};
  static String? _currentUsername;

  late final Dio _dio;
  late final Dio _casDio; // CAS 认证专用 Dio
  late final CookieJar _cookieJar;
  late final String _username;
  late final String _sessionKey; // Session ID 的存储键
  String? _sessionId;

  Dio get dio => _dio;
  Dio get casDio => _casDio;

  CookieJar get cookieJar => _cookieJar;

  String get username => _username;

  String? get sessionId => _sessionId;

  bool get isLoggedIn => _sessionId != null;

  /// 获取按用户名隔离的 CookieJar
  static CookieJar _getCookieJar(String username) {
    if (kIsWeb) {
      return CookieJar();
    }
    return PersistCookieJar(
      storage: FileStorage(
        join(applicationSupportDirectory.path, 'cookies', username),
      ),
    );
  }

  /// 获取实例（按用户名管理）
  static ChangkeClient getInstance({String? username}) {
    username ??= _currentUsername ?? 'default';
    _currentUsername = username;

    if (_instances[username] == null) {
      final instance = ChangkeClient._();
      instance._username = username;
      instance._sessionKey = 'changke_session_id_$username';
      instance._cookieJar = _getCookieJar(username);

      // 创建主 Dio 实例（用于 tronclass API）
      instance._dio =
          Dio(
              BaseOptions(
                headers: {'User-Agent': _userAgent},
                followRedirects: false,
                validateStatus: (status) => status != null,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            )
            ..interceptors.addAll([
              CookieManager(instance._cookieJar),
              ChangkeAuthInterceptor(() => instance._sessionId),
              RedirectInterceptor(() => instance.dio),
            ]);

      // 创建 CAS Dio 实例（用于 CAS 认证）
      instance._casDio = Dio(
        BaseOptions(
          baseUrl: 'https://cas.guet.edu.cn/',
          headers: {'User-Agent': _userAgent},
          followRedirects: false,
          validateStatus: (status) => status != null,
          connectTimeout: const Duration(minutes: 1),
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      )..interceptors.addAll([
          CookieManager(instance._cookieJar),
          RedirectInterceptor(() => instance.casDio),
        ]);

      // setupHttpProxy(
      //   instance.casDio,
      //   proxyUrl: "http://172.16.0.163:9000",
      //   allowBadCertificate: true,
      // );

      // 从 GetStorage 同步读取 session
      instance._sessionId = getStorage.read<String>(instance._sessionKey);
      _instances[username] = instance;
    }
    return _instances[username]!;
  }

  /// 便捷访问当前用户实例
  static ChangkeClient get instance => getInstance();

  /// 登录：获取并保存新的 session
  Future<void> login({
    required String username,
    required String password,
    required CaptchaRequester captchaRequester,
  }) async {
    final session = await TronClassService.login(
      _casDio, // CAS 认证
      _dio, // 普通请求
      username: username,
      password: password,
      captchaHandler: (image) => captchaRequester(image),
    );
    _setSessionId(session);
  }

  /// 登出：清除 session
  void logout() {
    _setSessionId(null);
  }

  /// 设置 session ID（统一的读写入口）
  void _setSessionId(String? value) {
    _sessionId = value;
    if (value != null) {
      getStorage.write(_sessionKey, value);
    } else {
      getStorage.remove(_sessionKey);
    }
  }
}

class ChangkeAuthInterceptor extends Interceptor {
  final String? Function() getSessionId;

  ChangkeAuthInterceptor(this.getSessionId);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final url = options.uri.toString();
    if (!url.contains("https://courses.guet.edu.cn/")) {
      handler.next(options);
      return;
    }

    final sessionId = getSessionId();
    if (sessionId != null) {
      options.headers['x-session-id'] = sessionId;
    }
    handler.next(options);
  }
}
