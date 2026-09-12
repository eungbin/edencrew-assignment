import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

/// Naver 엔드포인트 호출에 필요한 공통 처리를 모아둔 얇은 HTTP 래퍼입니다.
///
/// - 타임아웃과 연결 실패를 [NetworkException]으로 통일합니다.
/// - 응답 헤더의 charset을 보고 EUC-KR 응답을 올바르게 디코딩합니다.
///   (일별 시세 HTML과 실시간 시세 JSON 모두 EUC-KR로 내려옵니다.)
class NaverHttpClient {
  NaverHttpClient({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 8);

  final http.Client _client;
  final Duration _timeout;

  /// 일부 엔드포인트는 UA가 없으면 차단하거나 다른 응답을 주기 때문에
  /// 일반 브라우저 UA를 붙여 요청합니다.
  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36',
    'Accept': '*/*',
  };

  /// [uri]를 GET으로 호출해 본문을 문자열로 돌려줍니다.
  Future<String> getString(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(_timeout);
    } on TimeoutException catch (e) {
      throw NetworkException('요청 시간이 초과되었습니다.', cause: e);
    } on SocketException catch (e) {
      throw NetworkException('네트워크에 연결할 수 없습니다.', cause: e);
    } on http.ClientException catch (e) {
      throw NetworkException('네트워크 요청에 실패했습니다.', cause: e);
    }

    if (response.statusCode != 200) {
      throw NetworkException(
        '서버 응답 오류 (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return decodeBody(response.bodyBytes, response.headers['content-type']);
  }

  /// Content-Type 헤더의 charset에 맞춰 바이트를 문자열로 디코딩합니다.
  ///
  /// charset이 없으면 UTF-8로 간주하되, 깨진 바이트가 있어도 예외 대신
  /// 대체 문자를 넣어 파싱이 계속되도록 합니다.
  static String decodeBody(List<int> bytes, String? contentType) {
    final String charset = _charsetOf(contentType);
    if (charset == 'euc-kr' ||
        charset == 'ks_c_5601-1987' ||
        charset == 'cp949' ||
        charset == 'ms949') {
      return eucKr.decode(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _charsetOf(String? contentType) {
    if (contentType == null) return 'utf-8';
    final RegExpMatch? match = RegExp(
      r'charset=([\w\-]+)',
      caseSensitive: false,
    ).firstMatch(contentType);
    return (match?.group(1) ?? 'utf-8').toLowerCase();
  }

  void close() => _client.close();
}
