import 'price_direction.dart';

/// 일별 시세 한 행입니다. 차트의 캔들 하나이자 표의 한 줄입니다.
class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.close,
    required this.change,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  /// `yyyyMMdd`로 정규화한 거래일
  final String date;
  final int close;

  /// 전일 대비 등락액. HTML의 `전일비` 컬럼과 방향 표시로 부호를 정합니다.
  final int change;
  final int open;
  final int high;
  final int low;
  final int volume;

  /// 표의 `등락` 컬럼 색상 기준 (전일 대비)
  PriceDirection get direction => PriceDirection.of(change);

  /// 캔들 색상 기준 (시가 대비 종가). 시가 == 종가면 보합 색을 씁니다.
  PriceDirection get candleDirection => PriceDirection.of(close - open);

  @override
  String toString() => 'DailyPrice($date c=$close o=$open h=$high l=$low)';
}
