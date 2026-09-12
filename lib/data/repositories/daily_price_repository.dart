import '../../domain/models/daily_price.dart';
import '../dto/daily_price_page_dto.dart';
import '../sources/naver_stock_api.dart';

/// 일별 시세를 **페이지 단위로 캐시**하며 필요한 거래일 수만큼만 받아옵니다.
///
/// 기간 탭이 `1개월 → 3개월`로 바뀌면 1·2페이지는 재사용하고 3~6페이지만 새로 받습니다.
/// `1년`도 25페이지를 한꺼번에 받지 않고, 없는 페이지만 소규모 병렬로 채웁니다.
class DailyPriceRepository {
  DailyPriceRepository(this._api, {int concurrency = 4})
    : _concurrency = concurrency;

  final NaverStockApi _api;
  final int _concurrency;

  static const int rowsPerPage = 10;

  final Map<String, _SymbolPages> _cache = <String, _SymbolPages>{};

  /// 이미 받아둔 범위 안에서 [days]개 거래일을 즉시 돌려줍니다. 네트워크를 쓰지 않습니다.
  /// 필요한 페이지가 하나라도 없으면 `null`입니다.
  List<DailyPrice>? cached(String symbol, int days) {
    final _SymbolPages? pages = _cache[symbol];
    if (pages == null) return null;
    final int need = _pagesFor(days);
    for (int p = 1; p <= need; p++) {
      if (pages.isBeyondLast(p)) break;
      if (!pages.has(p)) return null;
    }
    return pages.take(days);
  }

  /// [days]개 거래일을 최신순으로 돌려줍니다.
  Future<List<DailyPrice>> load(String symbol, int days) async {
    final _SymbolPages pages = _cache.putIfAbsent(symbol, _SymbolPages.new);
    final int need = _pagesFor(days);

    // 마지막 페이지를 모르면 1페이지부터 순서대로 확인하고,
    // 알고 있다면 lastPage를 넘는 요청은 만들지 않습니다.
    final List<int> missing = <int>[
      for (int p = 1; p <= need; p++)
        if (!pages.has(p) && !pages.isBeyondLast(p)) p,
    ];

    for (int i = 0; i < missing.length; i += _concurrency) {
      final List<int> chunk = missing.sublist(
        i,
        i + _concurrency > missing.length ? missing.length : i + _concurrency,
      );
      // 첫 청크가 lastPage를 알려주면 그 뒤 청크에서 넘치는 페이지는 건너뜁니다.
      final List<int> valid = chunk
          .where((int p) => !pages.isBeyondLast(p))
          .toList(growable: false);
      if (valid.isEmpty) break;

      final List<DailyPricePageDto> results = await Future.wait(
        valid.map((int p) => _api.dailyPrices(symbol, p)),
      );
      for (final DailyPricePageDto dto in results) {
        pages.put(dto);
      }
    }
    return pages.take(days);
  }

  static int _pagesFor(int days) => (days + rowsPerPage - 1) ~/ rowsPerPage;
}

/// 한 종목의 페이지 캐시입니다.
class _SymbolPages {
  final Map<int, List<DailyPrice>> _pages = <int, List<DailyPrice>>{};
  int? lastPage;

  bool has(int page) => _pages.containsKey(page);

  bool isBeyondLast(int page) => lastPage != null && page > lastPage!;

  void put(DailyPricePageDto dto) {
    _pages[dto.page] = dto.rows;
    lastPage = dto.lastPage;
  }

  /// 1페이지부터 이어 붙인 뒤 날짜 중복을 제거하고 [days]개만 돌려줍니다.
  ///
  /// 장중에 새 거래일이 생기면 페이지 경계가 한 칸 밀려 같은 날짜가 두 페이지에
  /// 걸칠 수 있어서 날짜 기준으로 한 번 걸러 냅니다.
  List<DailyPrice> take(int days) {
    final List<DailyPrice> merged = <DailyPrice>[];
    final Set<String> seen = <String>{};
    for (int p = 1; _pages.containsKey(p); p++) {
      for (final DailyPrice row in _pages[p]!) {
        if (seen.add(row.date)) merged.add(row);
      }
      if (merged.length >= days) break;
    }
    merged.sort((DailyPrice a, DailyPrice b) => b.date.compareTo(a.date));
    return merged.length > days ? merged.sublist(0, days) : merged;
  }
}
