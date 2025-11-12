import 'package:dio/dio.dart';
import 'package:tronclass/data/model/tron_class/rollcalls_response/rollcalls_response.dart';
import 'package:tronclass/data/service/login.dart';

class TronClassService {
  static Future<String> getLoginCode(
      Dio dio, String username, String password, CaptchaHandler captchaHandler) async {
    final url =
        "https://identity.guet.edu.cn/auth/realms/guet/protocol/openid-connect/auth";
    final params = {
      "scope": "openid",
      "response_type": "code",
      "redirect_uri": "https://mobile.guet.edu.cn/cas-callback?_h5=true",
      "client_id": "TronClassH5",
      "autologin": "true"
    };
    final resp = await dio.get(url, queryParameters: params);
    final redirectUrl = resp.requestOptions.uri;
    final redirectUrlString = redirectUrl.toString();

    Uri callbackUrl;
    if (redirectUrlString
        .contains("https://mobile.guet.edu.cn/cas-callback?_h5=true")) {
      callbackUrl = redirectUrl;
    } else {
      final serviceUrl = redirectUrl.queryParameters['service'];
      if (serviceUrl == null) {
        throw Exception(
            "ChangKeService.getLoginServiceUrl: 'service' param is null!");
      }

      final resp1 = await LoginService.loginCas(
          casDio: dio,
          username: username,
          password: password,
          service: serviceUrl,
          serviceHomeUrl: "https://mobile.guet.edu.cn/",
          successVerify: (resp) async {
            final uri = resp.requestOptions.uri;
            final code = uri.queryParameters['code'];
            final ok = code != null;
            return ok;
          },
          captchaHandler: captchaHandler);
      callbackUrl = resp1.requestOptions.uri;
    }

    final code = callbackUrl.queryParameters["code"]!;
    return code;
  }

  static Future<String> getAccessToken(Dio dio, {required String code}) async {
    final url =
        "https://identity.guet.edu.cn/auth/realms/guet/protocol/openid-connect/token";
    final params = {
      "client_id": "TronClassH5",
      "redirect_uri": "https://mobile.guet.edu.cn/cas-callback?_h5=true",
      "code": code,
      "grant_type": "authorization_code",
      "scope": "openid"
    };
    final resp = await dio.post(url,
        data: params,
        options: Options(contentType: "application/x-www-form-urlencoded"));
    final accessToken = resp.data['access_token'];
    if (accessToken == null) {
      throw Exception("ChangKeService.getAccessToken: 'access_token' is null!");
    }
    return accessToken;
  }

  static Future<String> loginDesktopEndpoint(Dio dio,
      {required String accessToken}) async {
    final url = "https://courses.guet.edu.cn/api/login?login=access_token";
    final data = {"access_token": accessToken, "org_id": 1};
    final resp = await dio.post(url, data: data);
    final sessionId = resp.headers.value('x-session-id');
    if (sessionId == null) {
      throw Exception(
          "ChangKeService.loginDesktopEndpoint: 'sessionId' is null!");
    }
    return sessionId;
  }

  static Future<String> login(
    Dio casDio,
    Dio dio, {
    required String username,
    required String password,
    required CaptchaHandler captchaHandler,
  }) async {
    final code = await getLoginCode(casDio, username, password, captchaHandler);
    final token = await getAccessToken(dio, code: code);
    final sessionId = await loginDesktopEndpoint(dio, accessToken: token);
    return sessionId;
  }

  static Future<Response<Map<String, dynamic>>> signQr(Dio dio,
      {required String rollcallId,
      required String data,
      required String deviceId}) async {
    final url =
        "https://courses.guet.edu.cn/api/rollcall/${rollcallId}/answer_qr_rollcall";
    final body = {
      "data": data,
      "deviceId": deviceId,
    };
    final resp = await dio.put<Map<String, dynamic>>(url,
        data: body, options: Options(responseType: ResponseType.json));
    return resp;
  }

  static Future<Response<Map<String, dynamic>>> signNumber(Dio dio,
      {required String rollcallId,
      required String numberCode,
      required String deviceId}) async {
    final url =
        "https://courses.guet.edu.cn/api/rollcall/${rollcallId}/answer_number_rollcall";
    final body = {
      "numberCode": numberCode,
      "deviceId": deviceId,
    };
    final resp = await dio.put<Map<String, dynamic>>(url,
        data: body, options: Options(responseType: ResponseType.json));
    return resp;
  }

  static Future<RollcallsResponse> getRollcalls(Dio dio) async {
    final url =
        "https://courses.guet.edu.cn/api/radar/rollcalls?api_version=1.1.0";
    final resp =
        await dio.get(url, options: Options(responseType: ResponseType.json));
    return RollcallsResponse.fromJson(resp.data);
  }

  static Future<Response<Map<String, dynamic>>> signRadar(
    Dio dio, {
    required String rollcallId,
    required String deviceId,
    required double latitude,
    required double longitude,
    required double accuracy,
    // You can use the default values
    double altitude = 0,
    // You can use the default values
    double? altitudeAccuracy,
    // You can use the default values
    double? speed,
    // You can use the default values
    String? heading,
  }) async {
    final url =
        "https://courses.guet.edu.cn/api/rollcall/${rollcallId}/answer?api_version=1.1.2";
    final body = {
      "deviceId": deviceId,
      "latitude": latitude,
      "longitude": longitude,
      "speed": speed,
      "accuracy": accuracy,
      "altitude": altitude,
      "altitudeAccuracy": altitudeAccuracy,
      "heading": heading
    };
    final resp = await dio.put<Map<String, dynamic>>(url,
        data: body, options: Options(responseType: ResponseType.json));
    return resp;
  }
}
