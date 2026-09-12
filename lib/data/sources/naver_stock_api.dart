import 'dart:convert';

import '../../core/errors/app_exception.dart';
import '../../core/network/naver_http_client.dart';
import '../dto/autocomplete_item_dto.dart';
import '../dto/daily_price_page_dto.dart';
import '../dto/realtime_quote_dto.dart';
import '../dto/stock_meta_dto.dart';

/// `docs/NAVER_API.md`의 endpoint 4개를 DTO로 돌려주는 원격 데이터 소스입니다.
///
/// 이 클래스는 URL 조립과 응답 → DTO 변환만 담당하고,
/// 캐시나 화면 모델 변환은 repository 계층이 맡습니다.
class NaverStockApi {
  const NaverStockApi(this._client);

  final NaverHttpClient _client;

  /// 1. 검색 자동완성
  Future<List<AutocompleteItemDto>> autocomplete(String query) async {
    final Uri uri = Uri.https('ac.stock.naver.com', '/ac', <String, String>{
      'q': query,
      'target': 'stock,ipo,index,marketindicator',
    });
    final Map<String, Object?> body = _decodeJsonObject(
      await _client.getString(uri),
    );
    final Object? items = body['items'];
    if (items is! List<Object?>) return const <AutocompleteItemDto>[];
    return items
        .whereType<Map<String, Object?>>()
        .map(AutocompleteItemDto.fromJson)
        .toList(growable: false);
  }

  /// 2. 실시간 시세. 여러 종목을 **한 번의 요청**으로 조회합니다.
  Future<List<RealtimeQuoteDto>> realtime(List<String> symbols) async {
    if (symbols.isEmpty) return const <RealtimeQuoteDto>[];
    final Uri uri = Uri.https(
      'polling.finance.naver.com',
      '/api/realtime',
      <String, String>{'query': 'SERVICE_ITEM:${symbols.join(',')}'},
    );
    final Map<String, Object?> body = _decodeJsonObject(
      await _client.getString(uri),
    );
    return RealtimeQuoteDto.listFromResponse(body);
  }

  /// 3. 종목 메타데이터 (종목명 · 거래소명)
  Future<StockMetaDto> meta(String symbol) async {
    final Uri uri = Uri.https(
      'stock.naver.com',
      '/api/securityFe/api/fchart/domestic/stock/$symbol',
    );
    return StockMetaDto.fromJson(_decodeJsonObject(await _client.getString(uri)));
  }

  /// 4. 일별 시세 HTML 한 페이지 (10거래일)
  Future<DailyPricePageDto> dailyPrices(String symbol, int page) async {
    final Uri uri = Uri.https(
      'finance.naver.com',
      '/item/sise_day.naver',
      <String, String>{'code': symbol, 'page': '$page'},
    );
    final String htmlText = await _client.getString(uri);
    return DailyPricePageDto.parse(htmlText, page: page);
  }

  static Map<String, Object?> _decodeJsonObject(String text) {
    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map<String, Object?>) return decoded;
      throw const ParseException('JSON 객체 형태가 아닙니다.');
    } on FormatException catch (e) {
      throw ParseException('JSON 응답을 해석하지 못했습니다.', cause: e);
    }
  }
}
