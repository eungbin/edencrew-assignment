import 'dart:math' as math;

/// 가격 축 눈금입니다. 화면 좌표 계산과 분리해 두어 단위 테스트가 가능합니다.
class PriceScale {
  const PriceScale({required this.min, required this.max, required this.ticks});

  /// 눈금에 맞춰 넓힌 축의 아래 · 위 끝값
  final double min;
  final double max;

  /// 오름차순 눈금 값
  final List<double> ticks;

  double get range => max - min;

  /// [low]~[high] 범위를 덮는 "보기 좋은" 눈금을 만듭니다.
  ///
  /// 1 · 2 · 2.5 · 5 × 10ⁿ 중에서 눈금이 [targetCount]개에 가장 가깝게 나오는 간격을 고르고,
  /// 축의 끝은 그 간격의 배수로 내림 · 올림합니다. 그래서 라벨이 `172,000`처럼 딱 떨어집니다.
  factory PriceScale.nice(num low, num high, {int targetCount = 5}) {
    double lo = math.min(low, high).toDouble();
    double hi = math.max(low, high).toDouble();
    if (hi - lo == 0) {
      // 값이 하나뿐이면 위아래로 1%를 벌려 눈금을 만들 수 있게 합니다.
      final double pad = math.max(1, hi.abs() * 0.01);
      lo -= pad;
      hi += pad;
    }

    final double step = _niceStep((hi - lo) / math.max(1, targetCount - 1));
    final double niceMin = (lo / step).floorToDouble() * step;
    final double niceMax = (hi / step).ceilToDouble() * step;

    final List<double> ticks = <double>[];
    for (double v = niceMin; v <= niceMax + step * 0.001; v += step) {
      ticks.add(_round(v));
    }
    return PriceScale(min: niceMin, max: niceMax, ticks: ticks);
  }

  static double _niceStep(double rawStep) {
    final double magnitude = math
        .pow(10, (math.log(rawStep) / math.ln10).floor())
        .toDouble();
    final double fraction = rawStep / magnitude;
    final double nice;
    if (fraction <= 1) {
      nice = 1;
    } else if (fraction <= 2) {
      nice = 2;
    } else if (fraction <= 2.5) {
      nice = 2.5;
    } else if (fraction <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  /// 부동소수 오차(`172000.00000001`)를 정리합니다.
  static double _round(double v) => (v * 1000).roundToDouble() / 1000;
}

/// 날짜 축에 표시할 캔들 인덱스입니다. 처음 · 가운데 · 마지막 세 개만 씁니다.
///
/// 1년(245개)처럼 캔들이 촘촘할 때 라벨이 겹치지 않도록 개수를 고정했습니다.
List<int> dateLabelIndices(int count) {
  if (count <= 0) return const <int>[];
  if (count == 1) return const <int>[0];
  if (count == 2) return const <int>[0, 1];
  return <int>[0, (count - 1) ~/ 2, count - 1];
}
