import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/daily_price.dart';
import '../../domain/models/quote.dart';
import '../../domain/models/stock.dart';

/// 기간 탭. `days`는 표와 차트에 보여줄 거래일 수이며, 저장소는 이를 10일 단위 페이지로 환산합니다.
enum ChartPeriod {
  month1('1개월', 20),
  month3('3개월', 60),
  month6('6개월', 120),
  year1('1년', 245);

  const ChartPeriod(this.label, this.days);

  final String label;
  final int days;
}

/// 종목 메타(종목명 · 거래소명). 상세 화면에서 메타 endpoint로 한 번 확인합니다.
final stockInfoProvider = FutureProvider.autoDispose.family<Stock, String>(
  (Ref ref, String symbol) =>
      ref.watch(stockRepositoryProvider).fetchStock(symbol),
);

/// 상세 화면의 현재가 · 요약 카드용 시세입니다.
final stockQuoteProvider = FutureProvider.autoDispose.family<Quote?, String>(
  (Ref ref, String symbol) =>
      ref.watch(stockRepositoryProvider).fetchQuote(symbol),
);

/// (종목, 기간) 별 일별 시세. 레코드를 키로 써서 같은 조합은 같은 provider를 공유합니다.
typedef DailyPricesKey = ({String symbol, ChartPeriod period});

final dailyPricesProvider = FutureProvider.autoDispose
    .family<List<DailyPrice>, DailyPricesKey>(
      (Ref ref, DailyPricesKey key) => ref
          .watch(dailyPriceRepositoryProvider)
          .load(key.symbol, key.period.days),
    );
