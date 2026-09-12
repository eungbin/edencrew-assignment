import 'price_direction.dart';

/// 실시간 시세 한 건입니다. 등락액 · 등락률 · 시가총액은 저장하지 않고 계산합니다.
class Quote {
  const Quote({
    required this.symbol,
    required this.price,
    required this.prevClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.listedShares,
  });

  final String symbol;

  /// 현재가 (`nv`)
  final int price;

  /// 전일 종가 (`pcv`)
  final int prevClose;
  final int open;
  final int high;
  final int low;

  /// 누적 거래량 (`aq`)
  final int volume;

  /// 상장 주식 수 (`countOfListedStock`)
  final int listedShares;

  /// 등락액 = 현재가 − 전일 종가
  int get change => price - prevClose;

  /// 등락률(%) = 등락액 / 전일 종가 × 100
  double get changeRate => prevClose == 0 ? 0 : change / prevClose * 100;

  PriceDirection get direction => PriceDirection.of(change);

  /// 시가총액 = 현재가 × 상장 주식 수. int 범위를 넘지 않도록 double로 둡니다.
  double get marketCap => price.toDouble() * listedShares.toDouble();
}
