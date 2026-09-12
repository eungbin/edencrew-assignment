import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/quote.dart';
import '../../domain/models/stock.dart';
import '../../shared/app_text_styles.dart';
import '../../shared/toast/toast_notifier.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../../theme/theme.dart';
import '../detail/detail_screen.dart';
import 'watchlist_providers.dart';
import 'widgets/sort_bottom_sheet.dart';
import 'widgets/watchlist_row.dart';

/// `01 · 관심` 화면입니다. 헤더 + 목록(또는 빈 상태)로 구성되고 탭 바는 셸이 그립니다.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Stock> stocks = ref.watch(sortedWatchlistProvider);
    final AsyncValue<Map<String, Quote>> quotes = ref.watch(
      watchlistQuotesProvider,
    );

    return Column(
      children: <Widget>[
        const _WatchlistHeader(),
        Expanded(
          child: stocks.isEmpty
              ? EmptyState(
                  icon: AppSvgIcon(
                    AppIcons.star40,
                    size: 40,
                    color: context.colors.textDisabled,
                  ),
                  title: '관심 종목이 없습니다',
                  description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
                )
              : _WatchlistBody(stocks: stocks, quotes: quotes),
        ),
      ],
    );
  }
}

class _WatchlistHeader extends ConsumerWidget {
  const _WatchlistHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final WatchlistSort sort = ref.watch(watchlistSortProvider);
    final bool refreshing = ref.watch(
      watchlistQuotesProvider.select((AsyncValue<Object?> v) => v.isLoading),
    );

    return SizedBox(
      height: 52,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '관심',
              style: AppTextStyles.title.copyWith(color: colors.textPrimary),
            ),
            Row(
              children: <Widget>[
                _SortChip(
                  sort: sort,
                  onTap: () => showSortBottomSheet(context, ref),
                ),
                SizedBox(width: dimens.space4),
                Semantics(
                  button: true,
                  label: '시세 새로고침',
                  child: InkResponse(
                    radius: dimens.space5,
                    onTap: refreshing
                        ? null
                        : () => ref
                              .read(watchlistQuotesProvider.notifier)
                              .refresh(),
                    child: SizedBox(
                      width: dimens.iconMd,
                      height: dimens.iconMd,
                      child: refreshing
                          ? Padding(
                              padding: const EdgeInsets.all(2),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.textSecondary,
                              ),
                            )
                          : AppSvgIcon(
                              AppIcons.refresh,
                              size: dimens.iconMd,
                              color: colors.textSecondary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 헤더 우측의 현재 정렬 기준 칩입니다. 누르면 정렬 바텀시트를 엽니다.
class _SortChip extends StatelessWidget {
  const _SortChip({required this.sort, required this.onTap});

  final WatchlistSort sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Semantics(
      button: true,
      label: '정렬 기준 ${sort.label}',
      child: InkWell(
        borderRadius: BorderRadius.circular(dimens.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dimens.space1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                sort.label,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              AppSvgIcon(
                AppIcons.align,
                size: dimens.iconMd,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistBody extends ConsumerWidget {
  const _WatchlistBody({required this.stocks, required this.quotes});

  final List<Stock> stocks;
  final AsyncValue<Map<String, Quote>> quotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final Map<String, Quote> quoteMap = quotes.value ?? const <String, Quote>{};
    final bool showError = quotes.hasError && !quotes.isLoading;

    return RefreshIndicator(
      color: colors.accentDefault,
      backgroundColor: colors.surfaceRaised,
      onRefresh: () => ref.read(watchlistQuotesProvider.notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: stocks.length + (showError ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (showError) {
            if (index == 0) {
              return _QuoteErrorBanner(
                onRetry: () =>
                    ref.read(watchlistQuotesProvider.notifier).refresh(),
              );
            }
            index -= 1;
          }
          final Stock stock = stocks[index];
          return Dismissible(
            key: ValueKey<String>(stock.symbol),
            direction: DismissDirection.endToStart,
            background: _DismissBackground(),
            onDismissed: (_) {
              ref.read(watchlistProvider.notifier).remove(stock.symbol);
              ref.read(toastProvider.notifier).show(ToastKind.favoriteRemoved);
            },
            child: WatchlistRow(
              stock: stock,
              quote: quoteMap[stock.symbol],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DetailScreen(stock: stock),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 스와이프 삭제 시 뒤에 드러나는 배경입니다.
class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Container(
      color: colors.surfaceSunken,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: context.dimens.space4),
      child: Icon(
        Icons.delete_outline_rounded,
        size: context.dimens.iconMd,
        color: colors.textSecondary,
      ),
    );
  }
}

/// 시세 조회가 실패했을 때 목록 위에 붙는 안내 줄입니다. 목록 자체는 스켈레톤으로 남깁니다.
class _QuoteErrorBanner extends StatelessWidget {
  const _QuoteErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      color: colors.surfaceRaised,
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space2,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: dimens.iconSm,
            color: colors.feedbackWarning,
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Text(
              '시세를 불러오지 못했습니다.',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: colors.accentDefault,
              padding: EdgeInsets.symmetric(horizontal: dimens.space2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('다시 시도', style: AppTextStyles.label),
          ),
        ],
      ),
    );
  }
}
