import 'package:edencrew_assignment_starter/domain/models/quote.dart';
import 'package:edencrew_assignment_starter/domain/models/stock.dart';
import 'package:edencrew_assignment_starter/features/watchlist/watchlist_providers.dart';
import 'package:flutter_test/flutter_test.dart';

Quote quote(String symbol, int price, int prevClose) => Quote(
  symbol: symbol,
  price: price,
  prevClose: prevClose,
  open: price,
  high: price,
  low: price,
  volume: 0,
  listedShares: 0,
);

void main() {
  const Stock samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
  const Stock hynix = Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피');
  const Stock kakao = Stock(symbol: '035720', name: '카카오', market: '코스피');
  const Stock ecopro = Stock(symbol: '247540', name: '에코프로비엠', market: '코스닥');
  const List<Stock> stocks = <Stock>[samsung, hynix, kakao, ecopro];

  final Map<String, Quote> quotes = <String, Quote>{
    '005930': quote('005930', 179700, 180100), // -0.22%
    '000660': quote('000660', 412500, 403000), // +2.36%
    '035720': quote('035720', 61300, 62100), // -1.29%
    // 에코프로비엠은 시세 없음 (스켈레톤)
  };

  group('sortWatchlist', () {
    test('가나다순은 종목명 오름차순이며 시세 유무와 무관하다', () {
      final List<String> names = sortWatchlist(
        stocks,
        quotes,
        WatchlistSort.name,
      ).map((Stock s) => s.name).toList();
      expect(names, <String>['SK하이닉스', '삼성전자', '에코프로비엠', '카카오']);
    });

    test('현재가순은 내림차순이고 시세 없는 종목은 맨 아래', () {
      final List<String> symbols = sortWatchlist(
        stocks,
        quotes,
        WatchlistSort.price,
      ).map((Stock s) => s.symbol).toList();
      expect(symbols, <String>['000660', '005930', '035720', '247540']);
    });

    test('등락률순은 내림차순이고 시세 없는 종목은 맨 아래', () {
      final List<String> symbols = sortWatchlist(
        stocks,
        quotes,
        WatchlistSort.changeRate,
      ).map((Stock s) => s.symbol).toList();
      expect(symbols, <String>['000660', '005930', '035720', '247540']);
    });

    test('값이 같으면 등록 순서를 유지한다', () {
      final Map<String, Quote> same = <String, Quote>{
        '005930': quote('005930', 100, 100),
        '000660': quote('000660', 100, 100),
        '035720': quote('035720', 100, 100),
      };
      final List<String> symbols = sortWatchlist(
        stocks,
        same,
        WatchlistSort.price,
      ).map((Stock s) => s.symbol).toList();
      expect(symbols, <String>['005930', '000660', '035720', '247540']);
    });

    test('시세가 하나도 없으면 등록 순서 그대로다', () {
      final List<Stock> sorted = sortWatchlist(
        stocks,
        const <String, Quote>{},
        WatchlistSort.changeRate,
      );
      expect(sorted, stocks);
    });
  });
}
