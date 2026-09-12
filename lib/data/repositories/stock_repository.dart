import '../../domain/models/quote.dart';
import '../../domain/models/stock.dart';
import '../dto/autocomplete_item_dto.dart';
import '../dto/realtime_quote_dto.dart';
import '../sources/naver_stock_api.dart';

/// 검색 · 시세 · 메타데이터를 앱 모델로 바꿔 제공합니다.
class StockRepository {
  StockRepository(this._api);

  final NaverStockApi _api;

  /// 종목 메타는 바뀌지 않으므로 앱이 살아 있는 동안 메모리에 캐시합니다.
  final Map<String, Stock> _metaCache = <String, Stock>{};

  /// 국내 6자리 종목만 남긴 검색 결과입니다.
  Future<List<Stock>> search(String query) async {
    final List<AutocompleteItemDto> items = await _api.autocomplete(query);
    final List<Stock> stocks = items
        .where((AutocompleteItemDto item) => item.isDomesticStock)
        .map((AutocompleteItemDto item) => item.toStock())
        .toList(growable: false);
    for (final Stock stock in stocks) {
      _metaCache[stock.symbol] = stock;
    }
    return stocks;
  }

  /// 여러 종목의 시세를 한 번에 조회해 symbol → Quote 맵으로 돌려줍니다.
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const <String, Quote>{};
    final List<RealtimeQuoteDto> dtos = await _api.realtime(symbols);
    return <String, Quote>{
      for (final RealtimeQuoteDto dto in dtos) dto.cd: dto.toQuote(),
    };
  }

  Future<Quote?> fetchQuote(String symbol) async =>
      (await fetchQuotes(<String>[symbol]))[symbol];

  /// 종목명 · 거래소명. 검색이나 관심 목록에서 이미 알고 있으면 요청하지 않습니다.
  Future<Stock> fetchStock(String symbol) async {
    final Stock? cached = _metaCache[symbol];
    if (cached != null) return cached;
    final Stock stock = (await _api.meta(symbol)).toStock();
    _metaCache[symbol] = stock;
    return stock;
  }

  /// 다른 경로(관심 목록 복원 등)로 알게 된 메타를 캐시에 넣어 둡니다.
  void primeStock(Stock stock) =>
      _metaCache.putIfAbsent(stock.symbol, () => stock);
}
