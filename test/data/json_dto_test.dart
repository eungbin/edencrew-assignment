import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/core/network/naver_http_client.dart';
import 'package:edencrew_assignment_starter/data/dto/autocomplete_item_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/realtime_quote_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/stock_meta_dto.dart';
import 'package:edencrew_assignment_starter/domain/models/quote.dart';
import 'package:edencrew_assignment_starter/domain/models/stock.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> readJson(String path, {String? contentType}) {
  final String text = NaverHttpClient.decodeBody(
    File(path).readAsBytesSync(),
    contentType,
  );
  return jsonDecode(text) as Map<String, Object?>;
}

void main() {
  group('AutocompleteItemDto', () {
    test('국내 6자리 종목만 남기고 Stock으로 변환한다', () {
      final Map<String, Object?> body = readJson(
        'assets/mock/autocomplete_samsung.json',
      );
      final List<AutocompleteItemDto> items = (body['items']! as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map(AutocompleteItemDto.fromJson)
          .toList();

      final List<Stock> stocks = items
          .where((AutocompleteItemDto i) => i.isDomesticStock)
          .map((AutocompleteItemDto i) => i.toStock())
          .toList();

      expect(stocks, isNotEmpty);
      expect(stocks.first.symbol, '005930');
      expect(stocks.first.name, '삼성전자');
      expect(stocks.first.market, '코스피');
      expect(stocks.first.id, 'domestic:005930');
      expect(stocks.first.label, '005930 · 코스피');
      for (final Stock s in stocks) {
        expect(s.symbol, matches(RegExp(r'^\d{6}$')));
      }
    });

    test('해외 · 지수 · 7자리 코드는 걸러진다', () {
      const AutocompleteItemDto foreign = AutocompleteItemDto(
        code: 'AAPL',
        name: 'Apple',
        typeCode: 'NASDAQ',
        typeName: '나스닥',
        nationCode: 'USA',
        category: 'stock',
      );
      const AutocompleteItemDto index = AutocompleteItemDto(
        code: 'KOSPI',
        name: '코스피',
        typeCode: 'KOSPI',
        typeName: '코스피',
        nationCode: 'KOR',
        category: 'index',
      );
      const AutocompleteItemDto etn = AutocompleteItemDto(
        code: '5800012',
        name: '어떤 ETN',
        typeCode: 'KOSPI',
        typeName: '코스피',
        nationCode: 'KOR',
        category: 'stock',
      );
      expect(foreign.isDomesticStock, isFalse);
      expect(index.isDomesticStock, isFalse);
      expect(etn.isDomesticStock, isFalse);
    });

    test('결과가 없으면 빈 배열이다', () {
      final Map<String, Object?> body = readJson(
        'assets/mock/autocomplete_empty.json',
      );
      expect(body['items'], isEmpty);
    });
  });

  group('RealtimeQuoteDto', () {
    test('EUC-KR JSON에서 여러 종목 시세를 읽고 파생값을 계산한다', () {
      final Map<String, Object?> body = readJson(
        'assets/mock/realtime_multi.json',
        contentType: 'text/plain;charset=EUC-KR',
      );
      final List<RealtimeQuoteDto> dtos = RealtimeQuoteDto.listFromResponse(
        body,
      );
      expect(dtos.map((RealtimeQuoteDto d) => d.cd), <String>[
        '005930',
        '000660',
        '035420',
      ]);

      final Quote samsung = dtos.first.toQuote();
      expect(samsung.price, 259500);
      expect(samsung.prevClose, 269000);
      expect(samsung.change, -9500);
      expect(samsung.changeRate, closeTo(-3.53, 0.01));
      expect(samsung.marketCap, closeTo(259500.0 * 5846278608, 1));
    });
  });

  group('StockMetaDto', () {
    test('종목명과 거래소 한글명을 Stock으로 옮긴다', () {
      final Stock stock = StockMetaDto.fromJson(
        readJson('assets/mock/meta_005930.json'),
      ).toStock();
      expect(stock.symbol, '005930');
      expect(stock.name, '삼성전자');
      expect(stock.market, '코스피');
    });
  });
}
