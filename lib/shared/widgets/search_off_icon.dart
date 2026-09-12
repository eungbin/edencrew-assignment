import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 검색 결과 없음 상태의 아이콘입니다. 돋보기 렌즈 **안에** X가 들어 있는 시안 모양입니다.
///
/// Material의 `search_off`는 X가 렌즈 바깥(왼쪽 아래)에 붙어 있어 시안과 달라 직접 그렸습니다.
/// 렌즈 · 손잡이 비율은 Material `search` 아이콘(24 기준 렌즈 반지름 9.5, 손잡이 끝 21)을 따릅니다.
class SearchOffIcon extends StatelessWidget {
  const SearchOffIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SearchOffPainter(color: color)),
    );
  }
}

class _SearchOffPainter extends CustomPainter {
  const _SearchOffPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.width / 24;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(9.5 * unit, 9.5 * unit);
    final double radius = 7.5 * unit;
    canvas.drawCircle(center, radius, stroke);

    // 손잡이: 렌즈 가장자리(45°)에서 오른쪽 아래 끝까지
    final double edge = radius / math.sqrt2;
    canvas.drawLine(
      center + Offset(edge, edge),
      Offset(21 * unit, 21 * unit),
      stroke,
    );

    // 렌즈 안의 X
    final double arm = 2.6 * unit;
    canvas.drawLine(
      center + Offset(-arm, -arm),
      center + Offset(arm, arm),
      stroke,
    );
    canvas.drawLine(
      center + Offset(arm, -arm),
      center + Offset(-arm, arm),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SearchOffPainter oldDelegate) =>
      oldDelegate.color != color;
}
