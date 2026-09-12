import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/quote.dart';
import '../../../domain/models/stock.dart';
import '../../../shared/app_text_styles.dart';
import '../../../shared/price_colors.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../../theme/theme.dart';

/// 관심 목록 한 행입니다. 시세가 없으면 우측을 스켈레톤으로 채웁니다.
///
/// 시안: 최소 높이 56, 패딩 12/16, 아래 테두리 1, 좌측 종목명 + `코드 · 시장`,
/// 우측 현재가 + 등락. 긴 종목명은 한 줄 말줄임으로 처리해 우측 숫자를 밀어내지 않게 합니다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({
    super.key,
    required this.stock,
    required this.quote,
    this.onTap,
  });

  final Stock stock;
  final Quote? quote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Material(
      color: colors.surfaceBase,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space4,
            vertical: dimens.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.borderSubtle,
                width: dimens.borderHairline,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.label,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: dimens.space3),
              _QuoteColumn(quote: quote),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteColumn extends StatelessWidget {
  const _QuoteColumn({required this.quote});

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Quote? q = quote;

    if (q == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SkeletonBox(width: 64, height: 16),
          SizedBox(height: 2),
          SkeletonBox(width: 48, height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          Formatters.number(q.price),
          style: AppTextStyles.bodyNum.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          Formatters.changeWithRate(q.change, q.changeRate),
          style: AppTextStyles.captionNum.copyWith(
            color: colors.priceText(q.direction),
          ),
        ),
      ],
    );
  }
}
