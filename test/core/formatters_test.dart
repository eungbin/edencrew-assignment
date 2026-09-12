import 'package:edencrew_assignment_starter/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters', () {
    test('천 단위 구분', () {
      expect(Formatters.number(179700), '179,700');
      expect(Formatters.number(0), '0');
      expect(Formatters.number(999), '999');
      expect(Formatters.number(1000), '1,000');
      expect(Formatters.number(-400), '-400');
      expect(Formatters.number(1234567), '1,234,567');
    });

    test('등락액 · 등락률 표기', () {
      expect(Formatters.changeWithRate(-400, -0.22), '-400 (-0.22%)');
      expect(Formatters.changeWithRate(9500, 2.36), '+9,500 (+2.36%)');
      expect(Formatters.changeWithRate(0, 0), '0 (0.00%)');
    });

    test('거래량 · 시가총액 축약', () {
      expect(Formatters.volumeAbbrev(29113466), '29,113천');
      expect(Formatters.volumeAbbrev(999), '999');
      expect(Formatters.marketCapAbbrev(1063.5 * 1000000000000), '1,063조');
      expect(Formatters.marketCapAbbrev(4532 * 100000000), '4,532억');
      expect(Formatters.marketCapAbbrev(3.2 * 10000), '3만');
    });

    test('날짜 MM.DD', () {
      expect(Formatters.monthDay('20260327'), '03.27');
    });
  });
}
