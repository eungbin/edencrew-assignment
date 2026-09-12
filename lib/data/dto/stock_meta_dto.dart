import '../../domain/models/stock.dart';

/// `GET https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}`
/// 응답입니다. 종목명과 거래소 한글명을 얻는 데 씁니다.
class StockMetaDto {
  const StockMetaDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  final String symbolCode;
  final String stockName;
  final String stockExchangeNameKor;

  factory StockMetaDto.fromJson(Map<String, Object?> json) => StockMetaDto(
    symbolCode: (json['symbolCode'] ?? '') as String,
    stockName: (json['stockName'] ?? '') as String,
    stockExchangeNameKor: (json['stockExchangeNameKor'] ?? '') as String,
  );

  Stock toStock() =>
      Stock(symbol: symbolCode, name: stockName, market: stockExchangeNameKor);
}
