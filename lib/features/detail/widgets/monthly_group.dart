import '../../../domain/models/daily_price.dart';
import '../../../domain/models/price_direction.dart';

/// 일별 시세를 달 단위로 묶은 그룹입니다.
///
/// 화면 로직과 분리해 두어 단위 테스트가 가능합니다.
class MonthlyGroup {
  const MonthlyGroup({required this.yearMonth, required this.rows});

  /// `yyyyMM` (예: `202609`)
  final String yearMonth;

  /// 그 달의 거래일. 입력과 같은 최신순입니다.
  final List<DailyPrice> rows;

  /// 섹션 헤더 표기 (예: `2026년 9월`)
  String get label {
    final String year = yearMonth.substring(0, 4);
    final int month = int.parse(yearMonth.substring(4, 6));
    return '$year년 $month월';
  }

  /// 그 달의 등락액 = 마지막 거래일 종가 − 첫 거래일 시가.
  ///
  /// 기간 탭 경계에 걸린 달은 일부 거래일만 들어오므로, 전월 종가가 아니라
  /// **받아온 범위 안의 첫 거래일 시가**를 기준으로 계산합니다. 그래야 화면에
  /// 보이는 행들만으로 설명이 되는 숫자가 됩니다.
  int get change => rows.first.close - rows.last.open;

  /// 그 달의 등락률(%)
  double get changeRate {
    final int base = rows.last.open;
    return base == 0 ? 0 : change / base * 100;
  }

  PriceDirection get direction => PriceDirection.of(change);
}

/// [prices](최신순)를 달 단위로 묶습니다. 그룹도 최신 달이 먼저 옵니다.
List<MonthlyGroup> groupByMonth(List<DailyPrice> prices) {
  final List<MonthlyGroup> groups = <MonthlyGroup>[];
  String? currentKey;
  List<DailyPrice> current = <DailyPrice>[];

  for (final DailyPrice price in prices) {
    final String key = price.date.substring(0, 6);
    if (key != currentKey) {
      if (currentKey != null) {
        groups.add(MonthlyGroup(yearMonth: currentKey, rows: current));
      }
      currentKey = key;
      current = <DailyPrice>[];
    }
    current.add(price);
  }
  if (currentKey != null) {
    groups.add(MonthlyGroup(yearMonth: currentKey, rows: current));
  }
  return groups;
}
