import '../../domain/models/quote.dart';

/// `GET https://polling.finance.naver.com/api/realtime` 응답의
/// `result.areas[].datas[]` 한 건입니다. 필드명은 Naver 축약어를 그대로 둡니다.
class RealtimeQuoteDto {
  const RealtimeQuoteDto({
    required this.cd,
    required this.nv,
    required this.pcv,
    required this.ov,
    required this.hv,
    required this.lv,
    required this.aq,
    required this.countOfListedStock,
  });

  final String cd;
  final int nv;
  final int pcv;
  final int ov;
  final int hv;
  final int lv;
  final int aq;
  final int countOfListedStock;

  factory RealtimeQuoteDto.fromJson(Map<String, Object?> json) {
    int readInt(String key) => ((json[key] ?? 0) as num).toInt();
    return RealtimeQuoteDto(
      cd: (json['cd'] ?? '') as String,
      nv: readInt('nv'),
      pcv: readInt('pcv'),
      ov: readInt('ov'),
      hv: readInt('hv'),
      lv: readInt('lv'),
      aq: readInt('aq'),
      countOfListedStock: readInt('countOfListedStock'),
    );
  }

  /// 응답 전체(`{"resultCode":..., "result": {"areas": [...]}}`)에서
  /// `SERVICE_ITEM` 영역의 시세 목록만 꺼냅니다.
  static List<RealtimeQuoteDto> listFromResponse(Map<String, Object?> body) {
    final Object? result = body['result'];
    if (result is! Map<String, Object?>) return const <RealtimeQuoteDto>[];
    final Object? areas = result['areas'];
    if (areas is! List<Object?>) return const <RealtimeQuoteDto>[];

    final List<RealtimeQuoteDto> quotes = <RealtimeQuoteDto>[];
    for (final Object? area in areas) {
      if (area is! Map<String, Object?>) continue;
      final Object? datas = area['datas'];
      if (datas is! List<Object?>) continue;
      for (final Object? data in datas) {
        if (data is Map<String, Object?>) {
          quotes.add(RealtimeQuoteDto.fromJson(data));
        }
      }
    }
    return quotes;
  }

  Quote toQuote() => Quote(
    symbol: cd,
    price: nv,
    prevClose: pcv,
    open: ov,
    high: hv,
    low: lv,
    volume: aq,
    listedShares: countOfListedStock,
  );
}
