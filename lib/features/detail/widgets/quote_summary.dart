import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/quote.dart';
import '../../../shared/app_text_styles.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../../theme/theme.dart';

/// 시가 · 고가 · 저가 / 거래량 · 시가총액 요약 카드 5개입니다.
///
/// 시안: 첫 줄 3칸, 둘째 줄 2칸, 간격 8. 카드는 라운드 8, 패딩 9/10, 배경 surface/sunken,
/// 라벨 11/14(text/secondary) 위에 값 15/20(text/primary).
class QuoteSummary extends StatelessWidget {
  const QuoteSummary({super.key, required this.quote});

  final AsyncValue<Quote?> quote;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final Quote? q = quote.value;
    final double gap = dimens.space2;

    String? value(String Function(Quote q) pick) => q == null ? null : pick(q);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double thirdWidth = (width - gap * 2) / 3;
        final double halfWidth = (width - gap) / 2;
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _Cell(
                  width: thirdWidth,
                  label: '시가',
                  value: value((Quote q) => Formatters.number(q.open)),
                ),
                SizedBox(width: gap),
                _Cell(
                  width: thirdWidth,
                  label: '고가',
                  value: value((Quote q) => Formatters.number(q.high)),
                ),
                SizedBox(width: gap),
                _Cell(
                  width: thirdWidth,
                  label: '저가',
                  value: value((Quote q) => Formatters.number(q.low)),
                ),
              ],
            ),
            SizedBox(height: gap),
            Row(
              children: <Widget>[
                _Cell(
                  width: halfWidth,
                  label: '거래량',
                  value: value((Quote q) => Formatters.volumeAbbrev(q.volume)),
                ),
                SizedBox(width: gap),
                _Cell(
                  width: halfWidth,
                  label: '시가총액',
                  value: value(
                    (Quote q) => Formatters.marketCapAbbrev(q.marketCap),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.label, required this.value});

  final double width;
  final String label;

  /// `null`이면 아직 시세를 받지 못한 상태라 스켈레톤을 그립니다.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(dimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 3),
          if (value == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: SkeletonBox(width: 56, height: 16),
            )
          else
            Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyNum.copyWith(color: colors.textPrimary),
            ),
        ],
      ),
    );
  }
}
