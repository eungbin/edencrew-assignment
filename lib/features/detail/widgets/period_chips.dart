import 'package:flutter/material.dart';

import '../../../shared/app_text_styles.dart';
import '../../../theme/theme.dart';
import '../detail_providers.dart';

/// 기간 탭 4개. 시안: 칩 높이 28, 라운드 8, 패딩 5/12, 간격 4, 글자 13/18 Regular.
/// 선택된 칩은 `accentDefault` 글자 + `accentBg` 배경입니다.
class PeriodChips extends StatelessWidget {
  const PeriodChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Row(
      children: <Widget>[
        for (final ChartPeriod period in ChartPeriod.values) ...<Widget>[
          if (period != ChartPeriod.values.first)
            SizedBox(width: dimens.space1),
          Expanded(
            child: _Chip(
              label: period.label,
              selected: period == selected,
              onTap: () => onSelected(period),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final BorderRadius radius = BorderRadius.circular(dimens.radiusMd);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.accentBg : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            height: 28,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: dimens.space3),
            child: Text(
              label,
              style: AppTextStyles.chip.copyWith(
                color: selected ? colors.accentDefault : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
