import 'dart:io';

import 'package:edencrew_assignment_starter/core/network/naver_http_client.dart';
import 'package:edencrew_assignment_starter/data/dto/daily_price_page_dto.dart';
import 'package:edencrew_assignment_starter/domain/models/daily_price.dart';
import 'package:edencrew_assignment_starter/domain/models/price_direction.dart';
import 'package:flutter_test/flutter_test.dart';

String loadEucKrHtml(String path) => NaverHttpClient.decodeBody(
  File(path).readAsBytesSync(),
  'text/html;charset=EUC-KR',
);

void main() {
  group('DailyPricePageDto.parse', () {
    late DailyPricePageDto page1;

    setUpAll(() {
      page1 = DailyPricePageDto.parse(
        loadEucKrHtml('assets/mock/sise_day_005930_p1.html'),
        page: 1,
      );
    });

    test('한 페이지에서 거래일 10건을 읽는다', () {
      expect(page1.rows, hasLength(10));
    });

    test('날짜를 yyyyMMdd로 정규화하고 숫자 컬럼 순서를 지킨다', () {
      final DailyPrice first = page1.rows.first;
      expect(first.date, '20260911');
      expect(first.close, 259500);
      expect(first.open, 258000);
      expect(first.high, 261500);
      expect(first.low, 256500);
      expect(first.volume, 13938673);
    });

    test('전일비의 방향 표시로 부호를 정한다 (하락 · 보합 · 상승)', () {
      final DailyPrice down = page1.rows[0]; // 2026.09.11 하락 9,500
      final DailyPrice flat = page1.rows[2]; // 2026.09.09 보합 0
      final DailyPrice up = page1.rows[4]; // 2026.09.07 상승
      expect(down.change, -9500);
      expect(down.direction, PriceDirection.down);
      expect(flat.change, 0);
      expect(flat.direction, PriceDirection.flat);
      expect(up.change, greaterThan(0));
      expect(up.direction, PriceDirection.up);
    });

    test('`맨뒤` 링크에서 마지막 페이지를 읽는다', () {
      expect(page1.lastPage, 756);
    });

    test('최신 거래일이 먼저 온다', () {
      for (int i = 1; i < page1.rows.length; i++) {
        expect(
          page1.rows[i - 1].date.compareTo(page1.rows[i].date),
          greaterThan(0),
        );
      }
    });

    test('표가 없는 HTML은 ParseException을 던진다', () {
      expect(
        () => DailyPricePageDto.parse('<html><body>차단</body></html>', page: 1),
        throwsA(isA<Exception>()),
      );
    });
  });
}
