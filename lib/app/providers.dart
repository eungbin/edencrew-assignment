import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/naver_http_client.dart';
import '../data/repositories/daily_price_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../data/repositories/watchlist_store.dart';
import '../data/sources/naver_stock_api.dart';

/// 앱 전역에서 하나만 존재하는 인프라 객체들입니다.
///
/// 화면(feature) 쪽 provider는 이 파일의 provider만 의존하고,
/// 테스트에서는 `ProviderScope(overrides: ...)`로 가짜 구현을 끼워 넣습니다.

/// `main()`에서 `SharedPreferences.getInstance()` 결과로 override 합니다.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError(
        'sharedPreferencesProvider는 main()에서 override 해야 합니다.',
      ),
    );

final Provider<NaverHttpClient> naverHttpClientProvider =
    Provider<NaverHttpClient>((Ref ref) {
      final NaverHttpClient client = NaverHttpClient();
      ref.onDispose(client.close);
      return client;
    });

final Provider<NaverStockApi> naverStockApiProvider = Provider<NaverStockApi>(
  (Ref ref) => NaverStockApi(ref.watch(naverHttpClientProvider)),
);

final Provider<StockRepository> stockRepositoryProvider =
    Provider<StockRepository>(
      (Ref ref) => StockRepository(ref.watch(naverStockApiProvider)),
    );

final Provider<DailyPriceRepository> dailyPriceRepositoryProvider =
    Provider<DailyPriceRepository>(
      (Ref ref) => DailyPriceRepository(ref.watch(naverStockApiProvider)),
    );

final Provider<WatchlistStore> watchlistStoreProvider =
    Provider<WatchlistStore>(
      (Ref ref) => WatchlistStore(ref.watch(sharedPreferencesProvider)),
    );
