import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../app_text_styles.dart';
import '../toast/toast_notifier.dart';
import 'app_icon.dart';
import 'app_tab_bar.dart';

/// 앱 전체 위에 토스트를 얹는 호스트입니다. `MaterialApp.builder`에서 감쌉니다.
///
/// 위치는 시안(`04 · 검색 · 관심 등록 토스트`)대로 하단 탭 바 위 12px 입니다.
/// 상세 화면처럼 탭 바가 없는 화면에서도 같은 높이에 띄워 위치가 튀지 않게 했습니다.
class ToastHost extends ConsumerWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ToastMessage? toast = ref.watch(toastProvider);
    final AppDimens dimens = context.dimens;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // 키보드가 올라와 있으면(검색 중 별을 누른 경우) 키보드 위 12px에 띄웁니다.
    final double bottom = keyboard > 0
        ? keyboard + dimens.space3
        : bottomInset + AppTabBar.barHeight + dimens.space3;

    return Stack(
      children: <Widget>[
        child,
        Positioned(
          left: dimens.space4,
          right: dimens.space4,
          bottom: bottom,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget widget, Animation<double> animation) {
                final Animation<Offset> slide = Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: widget),
                );
              },
              child: toast == null
                  ? const SizedBox.shrink()
                  : _ToastCard(key: ValueKey<int>(toast.id), kind: toast.kind),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({super.key, required this.kind});

  final ToastKind kind;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final bool added = kind == ToastKind.favoriteAdded;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceOverlay,
          borderRadius: BorderRadius.circular(dimens.radiusLg),
          border: Border.all(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
        child: Row(
          children: <Widget>[
            AppSvgIcon(
              added ? AppIcons.starFill22 : AppIcons.star22,
              size: 18,
              color: added ? colors.favoriteActive : colors.favoriteInactive,
            ),
            SizedBox(width: dimens.space2),
            Text(
              added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
              style: AppTextStyles.label.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
