import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:encrypt/encrypt.dart' as encrypt;

// 简化版 LoginService，仅包含 tronclass 需要的功能

Map<String, String?> _parseLoginHtml(String html) {
  final doc = html_parser.parse(html);
  final aesKey = doc.getElementById("pwdEncryptSalt")?.attributes["value"];
  final execution = doc.getElementById("execution")?.attributes["value"];
  return {"aesKey": aesKey, "execution": execution};
}

// AES 加密实现 - 按照 Rust 中的逻辑
String encryptPassword(String password, List<int> key) {
  try {
    if (key.length != 16 && key.length != 24 && key.length != 32) {
      throw ArgumentError("Key must be 16, 24, or 32 bytes long");
    }

    // 生成随机的 IV（16 字节）
    final random = Random.secure();
    final iv = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      iv[i] = random.nextInt(256);
    }

    // 生成 64 字节的随机字符串（字母数字字符）
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final randomStr = List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();

    // 拼接随机字符串和密码
    final plaintext = randomStr + password;

    // 使用 AES-128-CBC 加密
    final keyBytes = Uint8List.fromList(key);
    final encryptKey = encrypt.Key(keyBytes);
    final ivKey = encrypt.IV(iv);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encryptKey, mode: encrypt.AESMode.cbc, padding: 'PKCS7')
    );
    final encrypted = encrypter.encrypt(plaintext, iv: ivKey);

    // 返回 Base64 编码的加密结果
    return encrypted.base64;
  } catch (e) {
    // 如果加密失败，打印错误并重新抛出
    print("加密失败: $e");
    rethrow;
  }
}

class LoginService {
  static Future<Response> loginCas({
    required Dio casDio,
    required String username,
    required String password,
    required String service,
    required String serviceHomeUrl,
    required CaptchaHandler captchaHandler,
    required FutureOr<bool> Function(Response response) successVerify,
    String? firstGetUrl,
    Map<String, dynamic>? firstGetQueryParameters,
  }) async {
    // 获取登录页面
    var uri = firstGetUrl ?? "authserver/login";

    // 解决 cookie 不够误报密码错误的问题
    for (int retryCount = 0; retryCount < 3; retryCount++){
      await casDio.get(
        uri,
        queryParameters: firstGetQueryParameters ?? {'service': service},
      );
    }

    var resp = await casDio.get(
      uri,
      queryParameters: firstGetQueryParameters ?? {'service': service},
    );

    var reqUri = resp.requestOptions.uri;
    checkVerification(reqUri);
    if (await successVerify(resp)) {
      return resp;
    }
    check401(resp);

    // 解析登录页面，获取 aesKey 和 execution
    final parseLoginHtmlResult = _parseLoginHtml(resp.data);
    final aesKey = parseLoginHtmlResult["aesKey"];
    final execution = parseLoginHtmlResult["execution"];

    if (aesKey == null || execution == null) {
      throw LogonFailedException(
        'http request to ${resp.requestOptions.uri} failed: aesKey is null'
      );
    }

    // 获取验证码
    final captcha = await getCaptcha(casDio, username, captchaHandler);

    // 登录
    final uri1 = "authserver/login";
    final resp1 = await casDio.post(
      uri1,
      options: Options(
        contentType: "application/x-www-form-urlencoded",
        responseType: ResponseType.plain,
      ),
      queryParameters: {'service': service},
      data: {
        "username": username,
        "password": encryptPassword(password, utf8.encode(aesKey)),
        "rememberMe": true,
        "captcha": captcha,
        "_eventId": "submit",
        "cllt": "userNameLogin",
        "dllt": "generalLogin",
        "lt": "",
        "execution": execution
      },
    );

    reqUri = resp1.requestOptions.uri;
    checkVerification(reqUri);
    final success = await successVerify(resp1);
    if (success) {
      return resp1;
    }
    check401(resp1);
    throw LogonFailedException('Login failed');
  }

  static Future<String> getCaptcha(
    Dio dio,
    String username,
    CaptchaHandler captchaHandler,
  ) async {
    final checkNeedCaptchaResp = await dio.get(
      "authserver/checkNeedCaptcha.htl",
      queryParameters: {
        "username": username,
        "_": DateTime.timestamp().millisecondsSinceEpoch
      },
      options: Options(responseType: ResponseType.plain),
    );
    final checkNeedCaptcha = jsonDecode(checkNeedCaptchaResp.data);

    if (checkNeedCaptcha['isNeed'] == true) {
      final image = await dio.get(
        "authserver/getCaptcha.htl?${DateTime.timestamp().millisecondsSinceEpoch}",
        options: Options(responseType: ResponseType.bytes),
      );
      final captcha = await captchaHandler(image.data);
      return captcha;
    }
    return "";
  }

  static void check401(Response<dynamic> resp1) {
    if (resp1.statusCode == 401) {
      final html = resp1.data;
      final doc = html_parser.parse(html);
      final errorTip = doc.querySelector("#showErrorTip")?.text;
      throw LogonFailedException(
        "状态码：${resp1.statusCode} ${errorTip ?? 'Login failed'}"
      );
    }
  }

  static void checkVerification(Uri reqUri) {
    if (reqUri.toString().contains('/authserver/reAuthCheck/reAuthLoginView.do')) {
      throw RequireLoginVerificationCodeException('Verification code required');
    }
  }
}

typedef CaptchaHandler = Future<String> Function(Uint8List image);

class LogonFailedException implements Exception {
  final String msg;

  LogonFailedException(this.msg);

  @override
  String toString() => msg;
}

class RequireLoginVerificationCodeException implements Exception {
  final String msg;

  RequireLoginVerificationCodeException(this.msg);

  @override
  String toString() => msg;
}