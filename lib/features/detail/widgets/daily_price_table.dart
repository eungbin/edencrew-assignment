import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/models/daily_price.dart';
import '../../../shared/app_text_styles.dart';
import '../../../shared/price_colors.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../../theme/theme.dart';
import 'monthly_group.dart';

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

/// 일별 시세를 **달 단위로 접었다 펼 수 있는** 표입니다.
///
/// 1년이면 거래일이 245개라 한 줄씩 나열하면 원하는 날짜를 찾기 어렵습니다.
/// 사용자가 실제로 떠올리는 단위(`2026년 9월`)로 묶으면 화면이 짧아지고
/// 원하는 달로 바로 갈 수 있습니다. 기본은 가장 최근 달만 펼칩니다.
///
/// 행이 많아도 sliver로 그려 보이는 부분만 위젯을 만듭니다.
class DailyPriceRows extends StatefulWidget {
  const DailyPriceRows({super.key, required this.daily});

  final AsyncValue<List<DailyPrice>> daily;

  @override
  State<DailyPriceRows> createState() => _DailyPriceRowsState();
}

class _DailyPriceRowsState extends State<DailyPriceRows> {
  /// 펼쳐 둔 달(`yyyyMM`). 여러 달을 동시에 펼칠 수 있습니다.
  final Set<String> _expanded = <String>{};

  /// 기본 펼침을 적용한 데이터의 서명입니다.
  /// 기간 탭을 바꿔 목록이 달라지면 펼침 상태를 최근 달 하나로 되돌립니다.
  String? _defaultAppliedFor;

  void _syncDefaultExpansion(List<MonthlyGroup> groups) {
    if (groups.isEmpty) return;
    final String signature = '${groups.first.yearMonth}:${groups.length}';
    if (_defaultAppliedFor == signature) return;
    _defaultAppliedFor = signature;
    _expanded
      ..clear()
      ..add(groups.first.yearMonth);
  }

  @override
  Widget build(BuildContext context) {
    final List<DailyPrice>? rows = widget.daily.value;

    if (rows == null) {
      if (widget.daily.hasError) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      // 첫 로딩: 5줄 스켈레톤
      return SliverList.builder(
        itemCount: 5,
        itemBuilder: (BuildContext context, int index) => const _SkeletonRow(),
      );
    }

    final List<MonthlyGroup> groups = groupByMonth(rows);
    _syncDefaultExpansion(groups);

    // 섹션 헤더와 펼쳐진 행을 하나의 평평한 목록으로 만들어 sliver에 넘깁니다.
    final List<Widget> children = <Widget>[];
    for (final MonthlyGroup group in groups) {
      final bool expanded = _expanded.contains(group.yearMonth);
      children.add(
        _MonthHeader(
          group: group,
          expanded: expanded,
          onTap: () => setState(() {
            if (!_expanded.remove(group.yearMonth)) {
              _expanded.add(group.yearMonth);
            }
          }),
        ),
      );
      if (expanded) {
        children.addAll(group.rows.map((DailyPrice p) => _DailyRow(price: p)));
      }
    }

    return SliverList.builder(
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) => children[index],
    );
  }
}

/// 달 섹션 헤더입니다. 접혀 있어도 그 달의 거래일 수와 등락이 보입니다.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.group,
    required this.expanded,
    required this.onTap,
  });

  final MonthlyGroup group;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Semantics(
      button: true,
      expanded: expanded,
      label: '${group.label} 일별 시세',
      child: Material(
        color: colors.surfaceRaised,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: dimens.space2),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.borderSubtle,
                  width: dimens.borderHairline,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  group.label,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(width: dimens.space2),
                Text(
                  '${group.rows.length}일',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.changeWithRate(group.change, group.changeRate),
                  style: AppTextStyles.captionNum.copyWith(
                    color: colors.priceText(group.direction),
                  ),
                ),
                SizedBox(width: dimens.space2),
                // 펼침 표시: 시안에 별도 아이콘이 없어 뒤로 가기 셰브론을 회전해 씁니다.
                RotatedBox(
                  quarterTurns: expanded ? 1 : 3,
                  child: AppSvgIcon(
                    AppIcons.back,
                    size: dimens.iconSm,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
