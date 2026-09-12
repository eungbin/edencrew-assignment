import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/watchlist_store.dart';
import '../../domain/models/quote.dart';
import '../../domain/models/stock.dart';

/// 관심 목록 정렬 기준입니다. 헤더 칩 문구와 바텀시트 항목 이름으로도 씁니다.
enum WatchlistSort {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const WatchlistSort(this.label);

  final String label;

  static WatchlistSort fromKey(String? key) => WatchlistSort.values.firstWhere(
    (WatchlistSort s) => s.name == key,
    orElse: () => WatchlistSort.name,
  );
}

/// 관심 종목 목록(등록 순서)입니다. 세 화면의 별 아이콘이 모두 이 상태를 봅니다.
///
/// 변경될 때마다 로컬에 저장하므로 앱을 다시 켜도 유지됩니다.
class WatchlistNotifier extends Notifier<List<Stock>> {
  @override
  List<Stock> build() {
    final WatchlistStore store = ref.watch(watchlistStoreProvider);
    final List<Stock> stocks = store.loadStocks();
    for (final Stock stock in stocks) {
      ref.read(stockRepositoryProvider).primeStock(stock);
    }
    return stocks;
  }

  bool contains(String symbol) => state.any((Stock s) => s.symbol == symbol);

  /// 등록되어 있으면 해제하고 없으면 등록합니다. 등록됐으면 `true`를 돌려줍니다.
  bool toggle(Stock stock) {
    if (contains(stock.symbol)) {
      remove(stock.symbol);
      return false;
    }
    add(stock);
    return true;
  }

  void add(Stock stock) {
    if (contains(stock.symbol)) return;
    state = <Stock>[...state, stock];
    _persist();
  }

  void remove(String symbol) {
    state = state
        .where((Stock s) => s.symbol != symbol)
        .toList(growable: false);
    _persist();
  }

  void _persist() {
    ref.read(watchlistStoreProvider).saveStocks(state);
  }
}

final NotifierProvider<WatchlistNotifier, List<Stock>> watchlistProvider =
    NotifierProvider<WatchlistNotifier, List<Stock>>(WatchlistNotifier.new);

/// 특정 종목이 관심 목록에 있는지. 목록 전체가 아니라 이 값만 바뀔 때 리빌드됩니다.
final isFavoriteProvider = Provider.family<bool, String>(
  (Ref ref, String symbol) => ref.watch(
    watchlistProvider.select(
      (List<Stock> list) => list.any((Stock s) => s.symbol == symbol),
    ),
  ),
);

/// 정렬 기준. 로컬에 저장해 앱 재실행 후에도 유지합니다.
class WatchlistSortNotifier extends Notifier<WatchlistSort> {
  @override
  WatchlistSort build() =>
      WatchlistSort.fromKey(ref.watch(watchlistStoreProvider).loadSortKey());

  void set(WatchlistSort sort) {
    state = sort;
    ref.read(watchlistStoreProvider).saveSortKey(sort.name);
  }
}

final NotifierProvider<WatchlistSortNotifier, WatchlistSort>
watchlistSortProvider = NotifierProvider<WatchlistSortNotifier, WatchlistSort>(
  WatchlistSortNotifier.new,
);

/// 관심 종목 시세. 종목 구성이 바뀌면 다시 조회하고, 조회 중에는 이전 값을 유지합니다.
///
/// 종목 수와 무관하게 **요청은 항상 한 번**입니다. (`SERVICE_ITEM:005930,000660,...`)
class WatchlistQuotesNotifier extends AsyncNotifier<Map<String, Quote>> {
  @override
  Future<Map<String, Quote>> build() async {
    // 순서만 바뀌는 정렬은 재조회하지 않도록 심볼 목록을 문자열로 비교합니다.
    final String joined = ref.watch(
      watchlistProvider.select(
        (List<Stock> list) => list.map((Stock s) => s.symbol).join(','),
      ),
    );
    if (joined.isEmpty) return const <String, Quote>{};

    final List<String> symbols = joined.split(',');
    final Map<String, Quote> previous = state.value ?? const <String, Quote>{};
    final Map<String, Quote> fetched = await ref
        .read(stockRepositoryProvider)
        .fetchQuotes(symbols);

    // 새 응답에 빠진 종목이 있어도(일시적 누락) 직전 값을 남겨 스켈레톤으로 되돌아가지 않게 합니다.
    return <String, Quote>{
      for (final String symbol in symbols)
        if (fetched[symbol] != null || previous[symbol] != null)
          symbol: (fetched[symbol] ?? previous[symbol])!,
    };
  }

  /// 상단 새로고침 버튼 · pull to refresh 공용입니다.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // 실패는 state(AsyncError)로 화면에 전달되므로 여기서는 삼킵니다.
    }
  }
}

final AsyncNotifierProvider<WatchlistQuotesNotifier, Map<String, Quote>>
watchlistQuotesProvider =
    AsyncNotifierProvider<WatchlistQuotesNotifier, Map<String, Quote>>(
      WatchlistQuotesNotifier.new,
    );

/// 정렬이 적용된 관심 목록입니다.
final Provider<List<Stock>> sortedWatchlistProvider = Provider<List<Stock>>((
  Ref ref,
) {
  final List<Stock> stocks = ref.watch(watchlistProvider);
  final WatchlistSort sort = ref.watch(watchlistSortProvider);
  final Map<String, Quote> quotes =
      ref.watch(watchlistQuotesProvider).value ?? const <String, Quote>{};
  return sortWatchlist(stocks, quotes, sort);
});

/// 정렬 규칙 (순수 함수, 테스트 대상)
///
/// - 현재가순 · 등락률순: 내림차순. 값이 같으면 원래 순서를 유지합니다.
/// - 가나다순: 종목명 오름차순.
/// - **시세를 아직 받지 못한 종목은 맨 아래**에 등록 순서대로 둡니다.
///   숫자가 없는 행을 0으로 취급해 중간에 끼우면 "왜 저기 있지?"가 되고,
///   맨 위에 두면 스켈레톤이 화면을 차지해서 아래로 내리는 편이 자연스럽습니다.
List<Stock> sortWatchlist(
  List<Stock> stocks,
  Map<String, Quote> quotes,
  WatchlistSort sort,
) {
  if (sort == WatchlistSort.name) {
    final List<Stock> sorted = List<Stock>.of(stocks);
    sorted.sort((Stock a, Stock b) => a.name.compareTo(b.name));
    return sorted;
  }

  final List<Stock> withQuote = <Stock>[];
  final List<Stock> withoutQuote = <Stock>[];
  for (final Stock stock in stocks) {
    (quotes.containsKey(stock.symbol) ? withQuote : withoutQuote).add(stock);
  }

  double keyOf(Stock stock) {
    final Quote quote = quotes[stock.symbol]!;
    return sort == WatchlistSort.price
        ? quote.price.toDouble()
        : quote.changeRate;
  }

  // List.sort는 안정 정렬이 아니므로 인덱스를 함께 비교해 원래 순서를 지킵니다.
  final List<(int, Stock)> indexed = <(int, Stock)>[
    for (int i = 0; i < withQuote.length; i++) (i, withQuote[i]),
  ];
  indexed.sort(((int, Stock) a, (int, Stock) b) {
    final int byKey = keyOf(b.$2).compareTo(keyOf(a.$2));
    return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
  });

  return <Stock>[
    for (final (int, Stock) entry in indexed) entry.$2,
    ...withoutQuote,
  ];
}
