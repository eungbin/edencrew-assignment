/// 화면에서 쓰는 숫자 · 날짜 표기 규칙을 한곳에 모았습니다.
///
/// Figma의 숫자는 예시일 뿐이므로 값이 아니라 **형식**을 맞추는 것이 목적입니다.
abstract final class Formatters {
  /// `179700` → `179,700`, `-400` → `-400`
  static String number(num value) {
    final bool negative = value < 0;
    final String digits = value.abs().round().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return '${negative ? '-' : ''}$buffer';
  }

  /// `9500` → `+9,500`, `-400` → `-400`, `0` → `0`
  static String signedNumber(int value) {
    if (value > 0) return '+${number(value)}';
    return number(value);
  }

  /// `2.36` → `+2.36%`, `-0.22` → `-0.22%`, `0` → `0.00%`
  static String signedPercent(double rate) {
    final String body = '${rate.abs().toStringAsFixed(2)}%';
    if (rate > 0) return '+$body';
    if (rate < 0) return '-$body';
    return body;
  }

  /// 관심 목록 행의 등락 표기: `-400 (-0.22%)`, `+9,500 (+2.36%)`, `0 (0.00%)`
  static String changeWithRate(int change, double rate) {
    return '${signedNumber(change)} (${signedPercent(rate)})';
  }

  /// 거래량 축약: `29113466` → `29,113천`. 1천 미만은 그대로 표기합니다.
  static String volumeAbbrev(int volume) {
    if (volume.abs() < 1000) return number(volume);
    return '${number(volume ~/ 1000)}천';
  }

  /// 시가총액 축약: 조 단위 이상은 `1,063조`, 억 단위는 `4,532억`,
  /// 그 미만은 `만` 단위로 표기합니다.
  static String marketCapAbbrev(num won) {
    const int trillion = 1000000000000;
    const int hundredMillion = 100000000;
    const int tenThousand = 10000;
    if (won >= trillion) return '${number(won ~/ trillion)}조';
    if (won >= hundredMillion) return '${number(won ~/ hundredMillion)}억';
    if (won >= tenThousand) return '${number(won ~/ tenThousand)}만';
    return number(won);
  }

  /// `20260911` → `09.11`
  static String monthDay(String yyyyMMdd) {
    if (yyyyMMdd.length < 8) return yyyyMMdd;
    return '${yyyyMMdd.substring(4, 6)}.${yyyyMMdd.substring(6, 8)}';
  }
}
