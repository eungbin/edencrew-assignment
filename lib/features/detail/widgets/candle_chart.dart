import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/daily_price.dart';
import '../../../domain/models/price_direction.dart';
import '../../../shared/app_text_styles.dart';
import '../../../theme/theme.dart';
import 'chart_scale.dart';

/// 일별 시세로 그리는 캔들 차트입니다. 패키지 없이 `CustomPainter`로 그립니다.
///
/// 패키지를 쓰지 않은 이유: 캔들 색을 `chartLineUp / chartLineDown` 토큰으로 정확히 맞추고,
/// 축 · 거래량 바 같은 요소를 시안의 여백 안에 원하는 만큼만 넣기에는 직접 그리는 편이 짧았습니다.
///
/// 구성 (위에서 아래로)
/// - 캔들 영역 [candleHeight]: 오른쪽 [axisWidth]만큼은 가격 축 라벨 자리로 비웁니다.
/// - 간격 [gap]
/// - 거래량 영역 [volumeHeight]: 캔들과 같은 x 위치 · 너비의 막대 (`chartVolumeBar`)
/// - 날짜 라벨 줄 [dateLabelHeight]: 처음 · 가운데 · 마지막 거래일 (`MM.DD`)
///
/// 규칙
/// - 입력은 최신순 목록이며, 그릴 때는 왼쪽이 과거가 되도록 뒤집습니다.
/// - Y 범위는 기간 내 최저가~최고가를 "보기 좋은" 눈금([PriceScale.nice])에 맞춰 넓힙니다.
/// - 캔들 너비는 칸의 60%, 최소 1px. 시가 == 종가면 보합 색으로 1px 선을 긋습니다.
class CandleChart extends StatelessWidget {
  const CandleChart({super.key, required this.prices});

  /// 최신 거래일이 먼저 오는 목록
  final List<DailyPrice> prices;

  static const double candleHeight = 150;
  static const double gap = 6;
  static const double volumeHeight = 44;
  static const double dateLabelHeight = 18;
  static const double axisWidth = 44;

  /// 위젯 전체 높이. 시안의 차트 200에 날짜 라벨 줄만 더해집니다.
  static const double totalHeight =
      candleHeight + gap + volumeHeight + dateLabelHeight;

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
          volumeColor: colors.chartVolumeBar,
          gridColor: colors.borderSubtle,
          labelStyle: AppTextStyles.captionNum.copyWith(
            color: colors.chartAxisLabel,
          ),
        ),
        size: const Size(double.infinity, totalHeight),
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
    required this.volumeColor,
    required this.gridColor,
    required this.labelStyle,
  });

  /// 과거 → 최신 순서
  final List<DailyPrice> prices;
  final Color upColor;
  final Color downColor;
  final Color flatColor;
  final Color volumeColor;
  final Color gridColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty || size.isEmpty) return;

    final double plotWidth = size.width - CandleChart.axisWidth;
    final Rect candleRect = Rect.fromLTWH(
      0,
      0,
      plotWidth,
      CandleChart.candleHeight,
    );
    final Rect volumeRect = Rect.fromLTWH(
      0,
      candleRect.bottom + CandleChart.gap,
      plotWidth,
      CandleChart.volumeHeight,
    );
    final double dateLabelTop = volumeRect.bottom;

    int minLow = prices.first.low;
    int maxHigh = prices.first.high;
    int maxVolume = 0;
    for (final DailyPrice p in prices) {
      if (p.low < minLow) minLow = p.low;
      if (p.high > maxHigh) maxHigh = p.high;
      if (p.volume > maxVolume) maxVolume = p.volume;
    }
    final PriceScale scale = PriceScale.nice(minLow, maxHigh);

    double yOf(num price) =>
        candleRect.top + (scale.max - price) / scale.range * candleRect.height;

    _paintGridAndAxis(canvas, size, scale, yOf);
    _paintCandlesAndVolume(canvas, candleRect, volumeRect, maxVolume, yOf);
    _paintDateLabels(canvas, plotWidth, dateLabelTop);
  }

  void _paintGridAndAxis(
    Canvas canvas,
    Size size,
    PriceScale scale,
    double Function(num) yOf,
  ) {
    final Paint grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final double plotWidth = size.width - CandleChart.axisWidth;

    for (final double tick in scale.ticks) {
      final double y = yOf(tick);
      canvas.drawLine(Offset(0, y), Offset(plotWidth, y), grid);

      final TextPainter painter = _text(Formatters.number(tick));
      // 라벨은 눈금선에 세로 중앙을 맞추되, 차트 위아래로 삐져나가지 않게 고정합니다.
      final double top = (y - painter.height / 2).clamp(
        0.0,
        CandleChart.candleHeight - painter.height,
      );
      painter.paint(canvas, Offset(size.width - painter.width, top));
    }
  }

  void _paintCandlesAndVolume(
    Canvas canvas,
    Rect candleRect,
    Rect volumeRect,
    int maxVolume,
    double Function(num) yOf,
  ) {
    final double slot = candleRect.width / prices.length;
    final double bodyWidth = math.max(1, slot * 0.6);
    final Paint wick = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.butt;
    final Paint body = Paint()..style = PaintingStyle.fill;
    final Paint volume = Paint()..color = volumeColor;

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

      if (maxVolume > 0) {
        final double barHeight = math.max(
          1,
          volumeRect.height * p.volume / maxVolume,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            centerX - bodyWidth / 2,
            volumeRect.bottom - barHeight,
            bodyWidth,
            barHeight,
          ),
          volume,
        );
      }
    }
  }

  void _paintDateLabels(Canvas canvas, double plotWidth, double top) {
    final double slot = plotWidth / prices.length;
    final List<int> indices = dateLabelIndices(prices.length);
    for (int k = 0; k < indices.length; k++) {
      final int i = indices[k];
      final TextPainter painter = _text(Formatters.monthDay(prices[i].date));
      final double centerX = slot * i + slot / 2;
      // 처음 라벨은 왼쪽 끝, 마지막 라벨은 플롯 오른쪽 끝을 넘지 않게 정렬합니다.
      final double left = (centerX - painter.width / 2).clamp(
        0.0,
        math.max(0, plotWidth - painter.width),
      );
      final double y = top + (CandleChart.dateLabelHeight - painter.height) / 2;
      painter.paint(canvas, Offset(left, y));
    }
  }

  TextPainter _text(String value) {
    return TextPainter(
      text: TextSpan(text: value, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.prices != prices ||
      oldDelegate.upColor != upColor ||
      oldDelegate.downColor != downColor ||
      oldDelegate.flatColor != flatColor ||
      oldDelegate.volumeColor != volumeColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelStyle != labelStyle;
}
