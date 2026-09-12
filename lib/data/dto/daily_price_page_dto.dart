import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../core/errors/app_exception.dart';
import '../../domain/models/daily_price.dart';

/// `GET https://finance.naver.com/item/sise_day.naver?code=&page=` 한 페이지입니다.
///
/// JSON이 아니라 EUC-KR HTML이므로, 디코딩된 문자열을 받아 표를 파싱합니다.
class DailyPricePageDto {
  const DailyPricePageDto({
    required this.page,
    required this.lastPage,
    required this.rows,
  });

  final int page;

  /// 페이지 네비게이션의 `맨뒤` 링크에서 읽은 마지막 페이지 번호입니다.
  /// 링크가 없으면(마지막 근처 페이지) 네비게이션에 보이는 가장 큰 번호를 씁니다.
  final int lastPage;

  /// 최신 거래일이 먼저 오는 순서 그대로입니다. 한 페이지에 최대 10건입니다.
  final List<DailyPrice> rows;

  static final RegExp _pageParam = RegExp(r'page=(\d+)');

  /// [page]번 페이지의 HTML 문자열을 파싱합니다.
  static DailyPricePageDto parse(String htmlText, {required int page}) {
    final Document document = html_parser.parse(htmlText);

    final Element? table = document.querySelector('table.type2');
    if (table == null) {
      throw const ParseException('일별 시세 표를 찾지 못했습니다.');
    }

    final List<DailyPrice> rows = <DailyPrice>[];
    for (final Element tr in table.querySelectorAll('tr')) {
      final DailyPrice? row = _parseRow(tr);
      if (row != null) rows.add(row);
    }

    return DailyPricePageDto(
      page: page,
      lastPage: _parseLastPage(document, fallback: page),
      rows: rows,
    );
  }

  /// 표의 숫자 순서는 `종가, 전일비, 시가, 고가, 저가, 거래량` 입니다.
  /// 날짜 셀을 포함해 `td`가 7개가 아니면 구분선 · 헤더 행이므로 건너뜁니다.
  static DailyPrice? _parseRow(Element tr) {
    final List<Element> cells = tr.querySelectorAll('td');
    if (cells.length != 7) return null;

    final String dateText = _text(cells[0]);
    final RegExpMatch? dateMatch = RegExp(
      r'(\d{4})\.(\d{2})\.(\d{2})',
    ).firstMatch(dateText);
    if (dateMatch == null) return null;
    final String date =
        '${dateMatch.group(1)}${dateMatch.group(2)}${dateMatch.group(3)}';

    final int close = _int(cells[1]);
    final int changeAbs = _int(cells[2]);
    final int change = _changeSign(cells[2]) * changeAbs;

    return DailyPrice(
      date: date,
      close: close,
      change: change,
      open: _int(cells[3]),
      high: _int(cells[4]),
      low: _int(cells[5]),
      volume: _int(cells[6]),
    );
  }

  /// 전일비 셀의 `<em class="bu_p bu_pdn">` 클래스(또는 blind 텍스트)로 부호를 정합니다.
  /// 상한가 · 하한가는 `bu_pup2` / `bu_pdn2`처럼 접미어가 붙어서 prefix로 봅니다.
  static int _changeSign(Element cell) {
    final Element? em = cell.querySelector('em');
    final String classes = em?.className ?? '';
    if (classes.contains('bu_pup')) return 1;
    if (classes.contains('bu_pdn')) return -1;
    final String blind = em?.text.trim() ?? '';
    if (blind.contains('상승') || blind.contains('상한')) return 1;
    if (blind.contains('하락') || blind.contains('하한')) return -1;
    return 0;
  }

  static int _parseLastPage(Document document, {required int fallback}) {
    final Element? last = document.querySelector('td.pgRR a');
    final int? fromLastLink = _pageOf(last?.attributes['href']);
    if (fromLastLink != null) return fromLastLink;

    int maxPage = fallback;
    for (final Element a in document.querySelectorAll('table.Nnavi a')) {
      final int? p = _pageOf(a.attributes['href']);
      if (p != null && p > maxPage) maxPage = p;
    }
    return maxPage;
  }

  static int? _pageOf(String? href) {
    if (href == null) return null;
    return int.tryParse(_pageParam.firstMatch(href)?.group(1) ?? '');
  }

  static String _text(Element cell) => cell.text.replaceAll(' ', ' ').trim();

  /// `13,938,673` → 13938673. 숫자가 없으면 0입니다.
  static int _int(Element cell) {
    final String digits = _text(cell).replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
