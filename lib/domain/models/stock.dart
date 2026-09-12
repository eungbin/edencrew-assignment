/// 종목 식별 정보입니다. 검색 결과 · 관심 목록 · 상세 헤더에서 공통으로 씁니다.
class Stock {
  const Stock({required this.symbol, required this.name, required this.market});

  /// 6자리 종목코드 (예: `005930`)
  final String symbol;

  /// 종목명 (예: `삼성전자`)
  final String name;

  /// 거래소 한글명 (예: `코스피`, `코스닥`)
  final String market;

  /// 국내 주식용 canonical id (`domestic:005930`).
  String get id => 'domestic:$symbol';

  /// 화면 두 번째 줄에 쓰는 `005930 · 코스피` 표기입니다.
  String get label => '$symbol · $market';

  Stock copyWith({String? name, String? market}) => Stock(
    symbol: symbol,
    name: name ?? this.name,
    market: market ?? this.market,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'symbol': symbol,
    'name': name,
    'market': market,
  };

  factory Stock.fromJson(Map<String, Object?> json) => Stock(
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    market: json['market'] as String,
  );

  @override
  bool operator ==(Object other) => other is Stock && other.symbol == symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => 'Stock($symbol $name $market)';
}
