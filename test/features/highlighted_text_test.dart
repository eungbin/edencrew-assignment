import 'package:edencrew_assignment_starter/features/search/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const TextStyle base = TextStyle(color: Color(0xFFFAF9F5));
  const Color highlight = Color(0xFF8B7CF6);

  List<(String, bool)> segments(String text, String query) =>
      HighlightedText.buildSpans(text, query, base, highlight)
          .cast<TextSpan>()
          .map((TextSpan s) => (s.text!, s.style!.color == highlight))
          .toList();

  group('HighlightedText.buildSpans', () {
    test('검색어와 일치하는 앞부분만 강조한다', () {
      expect(segments('삼성전자', '삼성'), <(String, bool)>[
        ('삼성', true),
        ('전자', false),
      ]);
    });

    test('가운데 · 여러 번 일치해도 모두 강조한다', () {
      expect(segments('카카오카카오뱅크', '카카오'), <(String, bool)>[
        ('카카오', true),
        ('카카오', true),
        ('뱅크', false),
      ]);
    });

    test('대소문자를 구분하지 않고 원문 표기를 유지한다', () {
      expect(segments('SK하이닉스', 'sk'), <(String, bool)>[
        ('SK', true),
        ('하이닉스', false),
      ]);
    });

    test('일치 구간이 없거나(종목코드 검색) 검색어가 비면 원문 그대로다', () {
      expect(segments('삼성전자', '005930'), <(String, bool)>[('삼성전자', false)]);
      expect(segments('삼성전자', '  '), <(String, bool)>[('삼성전자', false)]);
    });
  });
}
