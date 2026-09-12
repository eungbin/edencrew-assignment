import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 관심 화면 헤더의 새로고침 아이콘입니다. 시안(`ico_refresh`)처럼 호 두 개에
/// 화살표가 각각 붙은 순환 화살표 모양입니다.
///
/// Material `refresh`는 호 하나에 화살표 하나라 시안과 달라 직접 그렸습니다.
/// 좌표는 24 기준 그리드로 잡고 [size]에 맞춰 비율로 축소합니다.
class RefreshIcon extends StatelessWidget {
  const RefreshIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RefreshPainter(color: color)),
    );
  }
}

class _RefreshPainter extends CustomPainter {
  const _RefreshPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = size.width / 24;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Rect circle = Rect.fromCircle(
      center: Offset(12 * u, 12 * u),
      radius: 9 * u,
    );
    // 위쪽 호: 왼쪽(3,12)에서 시계 방향으로 오른쪽 위(21,8) 근처까지
    const double topEnd = -24 * math.pi / 180; // atan2(8-12, 21-12)
    canvas.drawArc(
      circle,
      math.pi,
      topEnd + 2 * math.pi - math.pi,
      false,
      stroke,
    );
    // 아래쪽 호: 오른쪽(21,12)에서 시계 방향으로 왼쪽 아래(3,16) 근처까지
    const double bottomEnd = math.pi - 24 * math.pi / 180;
    canvas.drawArc(circle, 0, bottomEnd, false, stroke);

    // 화살촉 (ㄱ · ㄴ 모양)
    final Path arrows = Path()
      ..moveTo(21 * u, 3 * u)
      ..lineTo(21 * u, 8 * u)
      ..lineTo(16 * u, 8 * u)
      ..moveTo(3 * u, 21 * u)
      ..lineTo(3 * u, 16 * u)
      ..lineTo(8 * u, 16 * u);
    canvas.drawPath(arrows, stroke);
  }

  @override
  bool shouldRepaint(covariant _RefreshPainter oldDelegate) =>
      oldDelegate.color != color;
}
