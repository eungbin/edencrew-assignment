import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/daily_price.dart';
import '../../../shared/app_text_styles.dart';
import '../../../shared/price_colors.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../../theme/theme.dart';

/// `일별 시세` 표의 헤더 행입니다. 시안: 높이 32, 컬럼 간격 8, 11/14 text/secondary.
class DailyPriceHeader extends StatelessWidget {
  const DailyPriceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.caption.copyWith(
      color: context.colors.textSecondary,
    );
    return SizedBox(
      height: 32,
      child: _TableRow(
        cells: <Widget>[
          Text('날짜', style: style),
          Text('종가', style: style, textAlign: TextAlign.right),
          Text('등락', style: style, textAlign: TextAlign.right),
          Text('거래량', style: style, textAlign: TextAlign.right),
        ],
      ),
    );
  }
}

/// 표의 데이터 행들입니다. 행 수가 최대 245개라 sliver로 그려 보이는 부분만 만듭니다.
class DailyPriceRows extends StatelessWidget {
  const DailyPriceRows({super.key, required this.daily});

  final AsyncValue<List<DailyPrice>> daily;

  @override
  Widget build(BuildContext context) {
    final List<DailyPrice>? rows = daily.value;

    if (rows == null) {
      if (daily.hasError) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      // 첫 로딩: 5줄 스켈레톤
      return SliverList.builder(
        itemCount: 5,
        itemBuilder: (BuildContext context, int index) => const _SkeletonRow(),
      );
    }

    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int index) =>
          _DailyRow(price: rows[index]),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.price});

  final DailyPrice price;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextStyle secondary = AppTextStyles.captionNum.copyWith(
      color: colors.textSecondary,
    );

    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: context.dimens.borderHairline,
          ),
        ),
      ),
      child: _TableRow(
        cells: <Widget>[
          Text(Formatters.monthDay(price.date), style: secondary),
          Text(
            Formatters.number(price.close),
            textAlign: TextAlign.right,
            style: AppTextStyles.captionNum.copyWith(color: colors.textPrimary),
          ),
          Text(
            Formatters.signedNumber(price.change),
            textAlign: TextAlign.right,
            style: AppTextStyles.captionNum.copyWith(
              color: colors.priceText(price.direction),
            ),
          ),
          Text(
            Formatters.number(price.volume),
            textAlign: TextAlign.right,
            style: secondary,
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.borderSubtle,
            width: context.dimens.borderHairline,
          ),
        ),
      ),
      child: const _TableRow(
        cells: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: SkeletonBox(width: 36, height: 12),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 52, height: 12),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 36, height: 12),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 64, height: 12),
          ),
        ],
      ),
    );
  }
}

/// 4개 컬럼을 같은 너비로 나누고 컬럼 사이 8을 둡니다. 첫 컬럼만 왼쪽 정렬입니다.
class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final double gap = context.dimens.space2;
    return Row(
      children: <Widget>[
        for (int i = 0; i < cells.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: Align(
              alignment: i == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: cells[i],
            ),
          ),
        ],
      ],
    );
  }
}
