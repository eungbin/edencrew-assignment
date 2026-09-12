import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/stock.dart';
import '../../features/watchlist/watchlist_providers.dart';
import '../../theme/theme.dart';
import '../toast/toast_notifier.dart';
import 'app_icon.dart';

/// 관심 등록/해제 별 버튼입니다. 검색 결과 행과 상세 헤더에서 같이 씁니다.
///
/// 상태는 [watchlistProvider] 하나에서만 읽기 때문에 어느 화면에서 눌러도
/// 세 화면의 별이 동시에 바뀝니다. 누르면 토스트도 함께 띄웁니다.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.stock, this.size = 22});

  final Stock stock;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFavorite = ref.watch(isFavoriteProvider(stock.symbol));
    final AppColors colors = context.colors;

    return Semantics(
      button: true,
      label: isFavorite ? '관심 해제' : '관심 등록',
      child: InkResponse(
        radius: size,
        onTap: () {
          final bool added = ref.read(watchlistProvider.notifier).toggle(stock);
          ref
              .read(toastProvider.notifier)
              .show(
                added ? ToastKind.favoriteAdded : ToastKind.favoriteRemoved,
              );
        },
        child: SizedBox(
          width: size,
          height: size,
          child: AppSvgIcon(
            isFavorite ? AppIcons.starFill22 : AppIcons.star22,
            size: size,
            color: isFavorite ? colors.favoriteActive : colors.favoriteInactive,
          ),
        ),
      ),
    );
  }
}
