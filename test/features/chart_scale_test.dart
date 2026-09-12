import 'package:edencrew_assignment_starter/features/detail/widgets/chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PriceScale.nice', () {
    test('범위를 덮는 딱 떨어지는 눈금을 만든다', () {
      final PriceScale s = PriceScale.nice(172000, 181700);
      expect(s.min, lessThanOrEqualTo(172000));
      expect(s.max, greaterThanOrEqualTo(181700));
      expect(s.ticks.first, s.min);
      expect(s.ticks.last, s.max);
      // 간격 1·2·2.5·5 × 10ⁿ 중 하나 (여기서는 2,500)
      expect(s.ticks, <double>[170000, 172500, 175000, 177500, 180000, 182500]);
    });

    test('눈금 개수는 목표(5)에 가깝고 7개를 넘지 않는다', () {
      for (final (int lo, int hi) in <(int, int)>[
        (1596000, 1856000),
        (26100, 26900),
        (74200, 374500),
        (999, 1001),
      ]) {
        final PriceScale s = PriceScale.nice(lo, hi);
        expect(s.ticks.length, inInclusiveRange(3, 7), reason: '$lo~$hi');
        expect(s.min, lessThanOrEqualTo(lo));
        expect(s.max, greaterThanOrEqualTo(hi));
      }
    });

    test('최저가와 최고가가 같아도 범위가 0이 되지 않는다', () {
      final PriceScale s = PriceScale.nice(50000, 50000);
      expect(s.range, greaterThan(0));
      expect(s.ticks.length, greaterThanOrEqualTo(2));
    });
  });

  group('dateLabelIndices', () {
    test('처음 · 가운데 · 마지막 인덱스를 돌려준다', () {
      expect(dateLabelIndices(245), <int>[0, 122, 244]);
      expect(dateLabelIndices(20), <int>[0, 9, 19]);
    });

    test('캔들이 적으면 있는 만큼만 돌려준다', () {
      expect(dateLabelIndices(0), isEmpty);
      expect(dateLabelIndices(1), <int>[0]);
      expect(dateLabelIndices(2), <int>[0, 1]);
    });
  });
}
