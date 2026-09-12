import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../app_text_styles.dart';
import 'app_icon.dart';

/// 관심 / 검색 화면을 오가는 하단 탭 바입니다.
///
/// Material `BottomNavigationBar`는 높이 · 라벨 크기 · 간격이 시안과 달라
/// 시안 수치(위 테두리 1, 상하 패딩 8, 아이콘 22, 간격 3, 라벨 11/14)로 직접 그렸습니다.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// 위 테두리 1 + 패딩 8 + 아이콘 22 + 간격 3 + 라벨 14 + 패딩 8 + 탭 안쪽 패딩 4×2
  static const double barHeight = 63;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dimens.space2),
          child: Row(
            children: <Widget>[
              _TabItem(
                icon: AppIcons.starFill22,
                label: '관심',
                selected: currentIndex == 0,
                onTap: () => onSelected(0),
              ),
              _TabItem(
                icon: AppIcons.search22,
                label: '검색',
                selected: currentIndex == 1,
                onTap: () => onSelected(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color color = selected ? colors.navActive : colors.navInactive;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.dimens.space1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppSvgIcon(icon, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
