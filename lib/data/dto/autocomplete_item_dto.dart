import '../../domain/models/stock.dart';

/// `GET https://ac.stock.naver.com/ac` 응답의 `items[]` 한 건입니다.
class AutocompleteItemDto {
  const AutocompleteItemDto({
    required this.code,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.nationCode,
    required this.category,
  });

  final String code;
  final String name;

  /// `KOSPI`, `KOSDAQ`, `KONEX` 등
  final String typeCode;

  /// `코스피`, `코스닥` 등 화면에 그대로 쓰는 한글 거래소명
  final String typeName;

  /// `KOR`이면 국내
  final String nationCode;

  /// `stock`, `index`, `ipo`, `marketindicator`
  final String category;

  factory AutocompleteItemDto.fromJson(Map<String, Object?> json) {
    return AutocompleteItemDto(
      code: (json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      typeCode: (json['typeCode'] ?? '') as String,
      typeName: (json['typeName'] ?? '') as String,
      nationCode: (json['nationCode'] ?? '') as String,
      category: (json['category'] ?? '') as String,
    );
  }

  static final RegExp _sixDigits = RegExp(r'^\d{6}$');

  /// 국내 주식이면서 6자리 종목코드인 항목만 앱 모델로 옮깁니다.
  /// 지수 · 해외 · IPO 항목은 여기서 걸러집니다.
  bool get isDomesticStock =>
      nationCode == 'KOR' && category == 'stock' && _sixDigits.hasMatch(code);

  Stock toStock() => Stock(symbol: code, name: name, market: typeName);
}
