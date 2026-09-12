import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    // 달마다 섹션 하나. 섹션 안에서 헤더와 행 목록을 애니메이션으로 접었다 폅니다.
    return SliverList.builder(
      itemCount: groups.length,
      itemBuilder: (BuildContext context, int index) {
        final MonthlyGroup group = groups[index];
        return _MonthSection(
          key: ValueKey<String>(group.yearMonth),
          group: group,
          expanded: _expanded.contains(group.yearMonth),
          onToggle: () => setState(() {
            if (!_expanded.remove(group.yearMonth)) {
              _expanded.add(group.yearMonth);
            }
          }),
        );
      },
    );
  }
}

/// 달 하나의 헤더 + 행 목록입니다. 펼침 상태가 바뀌면 높이를 200ms 동안 부드럽게 바꿉니다.
///
/// 접혀서 애니메이션이 끝난 뒤에는 행 위젯을 아예 만들지 않습니다.
/// 1년(245행)에서 모든 달을 접어 두었을 때 보이지 않는 행이 메모리에 남지 않게 하기 위해서입니다.
class _MonthSection extends StatefulWidget {
  const _MonthSection({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggle,
  });

  final MonthlyGroup group;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
    value: widget.expanded ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didUpdateWidget(covariant _MonthSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _controller.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) => _revealRows());
      } else {
        _controller.reverse();
      }
    }
  }

  /// 펼치는 동안 스크롤을 함께 내려 그 달의 행이 모두 보이게 합니다.
  ///
  /// - 펼친 뒤 섹션 전체가 화면에 들어오면, 마지막 행이 화면 아래에 닿을 만큼만 내립니다.
  /// - 섹션이 화면보다 길면 헤더를 화면 맨 위에 붙입니다.
  /// - 이미 다 보이면 움직이지 않고, 위로 되돌리지도 않습니다.
  ///
  /// 스크롤 애니메이션을 높이 애니메이션과 같은 시간 · 곡선으로 돌리면
  /// 매 프레임 "늘어난 만큼만" 내려가서 목록 끝을 넘는 일이 없습니다.
  void _revealRows() {
    if (!mounted) return;
    final RenderObject? render = context.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return;
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      render,
    );
    if (viewport == null) return;

    final double rowsHeight = widget.group.rows.length * _DailyRow.height;
    final ScrollPosition position = scrollable.position;
    // 지금은 헤더만 있는 상태라, 펼쳐진 뒤의 바닥은 현재 바닥에 행 높이를 더한 위치입니다.
    final double alignBottom =
        viewport.getOffsetToReveal(render, 1.0).offset + rowsHeight;
    final double alignTop = viewport.getOffsetToReveal(render, 0.0).offset;
    final double maxAfterExpand = position.maxScrollExtent + rowsHeight;

    final double target = math.min(
      math.min(alignBottom, alignTop),
      maxAfterExpand,
    );
    if (target <= position.pixels + 0.5) return;

    position.animateTo(target, duration: _duration, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthHeader(
          group: widget.group,
          expanded: widget.expanded,
          rotation: _curve,
          onTap: widget.onToggle,
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            if (_controller.isDismissed) return const SizedBox.shrink();
            return ClipRect(
              child: SizeTransition(
                sizeFactor: _curve,
                alignment: Alignment.topCenter,
                child: FadeTransition(opacity: _curve, child: child),
              ),
            );
          },
          child: Column(
            children: <Widget>[
              for (final DailyPrice p in widget.group.rows) _DailyRow(price: p),
            ],
          ),
        ),
      ],
    );
  }
}

/// 달 섹션 헤더입니다. 접혀 있어도 그 달의 거래일 수와 등락이 보입니다.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.group,
    required this.expanded,
    required this.rotation,
    required this.onTap,
  });

  final MonthlyGroup group;
  final bool expanded;

  /// 0(접힘) → 1(펼침). 화살표를 아래에서 위로 돌리는 데 씁니다.
  final Animation<double> rotation;
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
                // 펼침 표시: 시안에 별도 아이콘이 없어 뒤로 가기 화살표를 아래로 돌려 두고,
                // 펼칠 때 반 바퀴 돌려 위를 가리키게 합니다.
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: 0.5).animate(rotation),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: AppSvgIcon(
                      AppIcons.back,
                      size: dimens.iconSm,
                      color: colors.textTertiary,
                    ),
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

  /// 시안의 표 행 높이. 펼칠 때 스크롤 양을 계산하는 데도 씁니다.
  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextStyle secondary = AppTextStyles.captionNum.copyWith(
      color: colors.textSecondary,
    );

    return Container(
      height: height,
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
