import 'package:edencrew_assignment_starter/domain/models/daily_price.dart';
import 'package:edencrew_assignment_starter/domain/models/price_direction.dart';
import 'package:edencrew_assignment_starter/features/detail/widgets/monthly_group.dart';
import 'package:flutter_test/flutter_test.dart';

DailyPrice price(String date, {int open = 100, int close = 100}) => DailyPrice(
  date: date,
  close: close,
  change: 0,
  open: open,
  high: close > open ? close : open,
  low: close < open ? close : open,
  volume: 1000,
);

void main() {
  group('groupByMonth', () {
    test('달이 바뀌는 지점에서 나누고 최신 달이 먼저 온다', () {
      final List<MonthlyGroup> groups = groupByMonth(<DailyPrice>[
        price('20260911'),
        price('20260910'),
        price('20260831'),
        price('20260730'),
        price('20260729'),
      ]);

      expect(groups.map((MonthlyGroup g) => g.yearMonth), <String>[
        '202609',
        '202608',
        '202607',
      ]);
      expect(groups.map((MonthlyGroup g) => g.rows.length), <int>[2, 1, 2]);
      expect(groups.first.rows.first.date, '20260911');
    });

    test('빈 입력은 빈 목록이다', () {
      expect(groupByMonth(const <DailyPrice>[]), isEmpty);
    });

    test('한 달짜리는 그룹 하나다', () {
      final List<MonthlyGroup> groups = groupByMonth(<DailyPrice>[
        price('20260903'),
        price('20260902'),
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.rows, hasLength(2));
    });
  });

  group('MonthlyGroup', () {
    test('헤더 문구는 `yyyy년 M월` 이다', () {
      expect(
        const MonthlyGroup(yearMonth: '202609', rows: <DailyPrice>[]).label,
        '2026년 9월',
      );
      expect(
        const MonthlyGroup(yearMonth: '202512', rows: <DailyPrice>[]).label,
        '2025년 12월',
      );
    });

    test('월간 등락은 첫 거래일 시가 대비 마지막 종가다', () {
      // 최신순: 9/11 종가 110, 9/01 시가 100 → +10 (+10%)
      final MonthlyGroup up = MonthlyGroup(
        yearMonth: '202609',
        rows: <DailyPrice>[
          price('20260911', open: 105, close: 110),
          price('20260901', open: 100, close: 105),
        ],
      );
      expect(up.change, 10);
      expect(up.changeRate, closeTo(10, 0.001));
      expect(up.direction, PriceDirection.up);

      final MonthlyGroup down = MonthlyGroup(
        yearMonth: '202608',
        rows: <DailyPrice>[
          price('20260831', open: 95, close: 90),
          price('20260801', open: 100, close: 95),
        ],
      );
      expect(down.change, -10);
      expect(down.direction, PriceDirection.down);

      final MonthlyGroup flat = MonthlyGroup(
        yearMonth: '202607',
        rows: <DailyPrice>[price('20260731', open: 100, close: 100)],
      );
      expect(flat.change, 0);
      expect(flat.direction, PriceDirection.flat);
    });
  });
}
