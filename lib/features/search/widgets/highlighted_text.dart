import 'package:flutter/material.dart';

/// [text] 안에서 [query]와 일치하는 모든 부분을 [highlightColor]로 칠해 한 줄로 그립니다.
///
/// 대소문자는 구분하지 않고, 검색어 앞뒤 공백은 무시합니다.
/// 종목코드로 검색했을 때처럼 이름에 일치 구간이 없으면 그냥 원문을 그립니다.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: buildSpans(text, query, style, highlightColor)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 테스트하기 쉽도록 span 생성만 따로 뺐습니다.
  static List<InlineSpan> buildSpans(
    String text,
    String query,
    TextStyle style,
    Color highlightColor,
  ) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return <InlineSpan>[TextSpan(text: text, style: style)];

    final String haystack = text.toLowerCase();
    final TextStyle highlighted = style.copyWith(color: highlightColor);
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    int index = haystack.indexOf(needle);
    while (index >= 0) {
      if (index > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + needle.length),
          style: highlighted,
        ),
      );
      cursor = index + needle.length;
      index = haystack.indexOf(needle, cursor);
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }
    return spans;
  }
}
