import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_text_styles.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../theme/theme.dart';
import '../watchlist_providers.dart';

/// `01 · 관심_sort`의 정렬 바텀시트를 엽니다. 항목을 고르면 바로 적용하고 닫힙니다.
Future<void> showSortBottomSheet(BuildContext context, WidgetRef ref) {
  final AppColors colors = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surfaceOverlay,
    barrierColor: colors.surfaceScrim,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.dimens.space4),
      ),
    ),
    builder: (BuildContext sheetContext) => SortBottomSheet(
      current: ref.read(watchlistSortProvider),
      onSelected: (WatchlistSort sort) {
        ref.read(watchlistSortProvider.notifier).set(sort);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final WatchlistSort current;
  final ValueChanged<WatchlistSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    // 시안의 하단 여백 34는 홈 인디케이터 영역입니다. 기기 inset이 더 작으면 최소 16을 둡니다.
    final double bottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      dimens.space4,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: dimens.space6),
            alignment: Alignment.centerLeft,
            child: Text(
              '정렬',
              style: AppTextStyles.title.copyWith(color: colors.textPrimary),
            ),
          ),
          for (final WatchlistSort sort in WatchlistSort.values)
            _SortOption(
              sort: sort,
              selected: sort == current,
              onTap: () => onSelected(sort),
            ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.sort,
    required this.selected,
    required this.onTap,
  });

  final WatchlistSort sort;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: dimens.space6, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              sort.label,
              style: AppTextStyles.body.copyWith(
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            if (selected)
              AppSvgIcon(AppIcons.check, size: 24, color: colors.textPrimary),
          ],
        ),
      ),
    );
  }
}
