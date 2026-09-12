import 'dart:io';

import 'package:edencrew_assignment_starter/core/network/naver_http_client.dart';
import 'package:edencrew_assignment_starter/data/repositories/daily_price_repository.dart';
import 'package:edencrew_assignment_starter/data/sources/naver_stock_api.dart';
import 'package:edencrew_assignment_starter/domain/models/daily_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 실제 HTML 샘플을 기반으로 페이지마다 날짜만 바꿔 응답하는 가짜 서버입니다.
/// `lastPage`는 3으로 고정해 "마지막 페이지 이후를 요청하지 않는지"도 검증합니다.
class FakeSiseServer {
  FakeSiseServer() {
    final List<int> bytes = File(
      'assets/mock/sise_day_005930_p1.html',
    ).readAsBytesSync();
    _template = NaverHttpClient.decodeBody(bytes, 'text/html;charset=EUC-KR');
  }

  late final String _template;
  final List<int> requestedPages = <int>[];

  http.Client get client => MockClient((http.Request request) async {
    final int page = int.parse(request.url.queryParameters['page']!);
    requestedPages.add(page);
    if (page > 3) {
      // 존재하지 않는 페이지: 네이버는 마지막 페이지를 반복해서 돌려주지만
      // 여기서는 호출 자체가 실패하도록 해 방어 로직을 검증합니다.
      return http.Response('', 500);
    }
    // 페이지별로 날짜 연도를 바꿔 중복되지 않는 10건을 만듭니다.
    final String body = _template
        .replaceAll('2026.', '${2026 - page}.')
        .replaceAll('page=756', 'page=3');
    return http.Response(body, 200, headers: <String, String>{
      'content-type': 'text/html;charset=utf-8',
    });
  });
}

void main() {
  late FakeSiseServer server;
  late DailyPriceRepository repository;

  setUp(() {
    server = FakeSiseServer();
    repository = DailyPriceRepository(
      NaverStockApi(NaverHttpClient(client: server.client)),
      concurrency: 2,
    );
  });

  test('필요한 페이지만 요청하고, 기간을 늘리면 받은 페이지를 재사용한다', () async {
    final List<DailyPrice> month = await repository.load('005930', 20);
    expect(month, hasLength(20));
    expect(server.requestedPages, <int>[1, 2]);

    // 3개월(60일)로 늘려도 1·2페이지는 다시 받지 않는다.
    await repository.load('005930', 60);
    expect(server.requestedPages.where((int p) => p == 1).length, 1);
    expect(server.requestedPages.where((int p) => p == 2).length, 1);
  });

  test('lastPage보다 큰 페이지는 요청하지 않는다', () async {
    final List<DailyPrice> rows = await repository.load('005930', 245);
    // lastPage = 3 이므로 최대 30건만 존재한다.
    expect(rows, hasLength(30));
    expect(server.requestedPages.every((int p) => p <= 3), isTrue);
  });

  test('같은 기간을 다시 요청하면 네트워크 없이 캐시로 답한다', () async {
    await repository.load('005930', 20);
    final int before = server.requestedPages.length;
    expect(repository.cached('005930', 20), hasLength(20));
    await repository.load('005930', 20);
    expect(server.requestedPages.length, before);
  });

  test('결과는 최신 날짜가 먼저 오고 날짜가 중복되지 않는다', () async {
    final List<DailyPrice> rows = await repository.load('005930', 30);
    final Set<String> dates = rows.map((DailyPrice r) => r.date).toSet();
    expect(dates.length, rows.length);
    for (int i = 1; i < rows.length; i++) {
      expect(rows[i - 1].date.compareTo(rows[i].date), greaterThan(0));
    }
  });
}
