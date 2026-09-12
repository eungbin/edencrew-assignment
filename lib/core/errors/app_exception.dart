/// 앱에서 사용자에게 보여줄 수 있는 형태로 정리한 예외입니다.
///
/// 네트워크 계층과 파싱 계층에서 발생한 원인을 [message] 한 줄로 요약해 두고,
/// UI는 종류에 따라 재시도 버튼이나 안내 문구를 다르게 보여줍니다.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// 사용자에게 그대로 노출해도 되는 한국어 문장입니다.
  final String message;

  /// 디버깅용 원인 객체입니다. 화면에는 표시하지 않습니다.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// 연결 실패, 타임아웃, 200이 아닌 응답 등 통신 단계의 실패입니다.
class NetworkException extends AppException {
  const NetworkException(super.message, {this.statusCode, super.cause});

  final int? statusCode;
}

/// 응답은 받았지만 기대한 형태가 아니어서 모델로 옮기지 못한 경우입니다.
class ParseException extends AppException {
  const ParseException(super.message, {super.cause});
}
