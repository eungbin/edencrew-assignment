import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/daily_price.dart';
import '../../../domain/models/price_direction.dart';
import '../../../theme/theme.dart';

/// 일별 시세로 그리는 캔들 차트입니다. 패키지 없이 `CustomPainter`로 그립니다.
///
/// 패키지를 쓰지 않은 이유: 캔들 색을 `chartLineUp / chartLineDown` 토큰으로 정확히 맞추고,
/// 시안처럼 축 · 격자 없이 캔들만 있는 최소 구성을 만들기에는 직접 그리는 편이 짧았습니다.
///
/// - 입력은 최신순 목록이며, 그릴 때는 왼쪽이 과거가 되도록 뒤집습니다.
/// - Y 범위는 기간 내 최저가~최고가에 위아래 4% 여유를 둡니다.
/// - 캔들 너비는 칸의 60%, 최소 1px. 시가 == 종가면 보합 색으로 1px 선을 긋습니다.
class CandleChart extends StatelessWidget {
  const CandleChart({super.key, required this.prices});

  /// 최신 거래일이 먼저 오는 목록
  final List<DailyPrice> prices;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CandlePainter(
          prices: prices.reversed.toList(growable: false),
          upColor: colors.chartLineUp,
          downColor: colors.chartLineDown,
          flatColor: colors.chartLineFlat,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.prices,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
  });

  /// 과거 → 최신 순서
  final List<DailyPrice> prices;
  final Color upColor;
  final Color downColor;
  final Color flatColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty || size.isEmpty) return;

    int minLow = prices.first.low;
    int maxHigh = prices.first.high;
    for (final DailyPrice p in prices) {
      if (p.low < minLow) minLow = p.low;
      if (p.high > maxHigh) maxHigh = p.high;
    }
    final double range = math.max(1, (maxHigh - minLow).toDouble());
    final double top = maxHigh + range * 0.04;
    final double bottom = minLow - range * 0.04;
    final double scale = size.height / (top - bottom);

    double yOf(num price) => (top - price) * scale;

    final double slot = size.width / prices.length;
    final double bodyWidth = math.max(1, slot * 0.6);
    final Paint wick = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.butt;
    final Paint body = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < prices.length; i++) {
      final DailyPrice p = prices[i];
      final Color color = switch (p.candleDirection) {
        PriceDirection.up => upColor,
        PriceDirection.down => downColor,
        PriceDirection.flat => flatColor,
      };
      final double centerX = slot * i + slot / 2;

      wick.color = color;
      canvas.drawLine(
        Offset(centerX, yOf(p.high)),
        Offset(centerX, yOf(p.low)),
        wick,
      );

      final double openY = yOf(p.open);
      final double closeY = yOf(p.close);
      final double bodyTop = math.min(openY, closeY);
      // 시가 == 종가인 날도 보이도록 몸통을 최소 1px로 유지합니다.
      final double bodyHeight = math.max(1, (openY - closeY).abs());
      body.color = color;
      canvas.drawRect(
        Rect.fromLTWH(centerX - bodyWidth / 2, bodyTop, bodyWidth, bodyHeight),
        body,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.prices != prices ||
      oldDelegate.upColor != upColor ||
      oldDelegate.downColor != downColor ||
      oldDelegate.flatColor != flatColor;
}
