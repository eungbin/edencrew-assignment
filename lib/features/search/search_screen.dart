import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/stock.dart';
import '../../shared/app_text_styles.dart';
import '../../shared/widgets/empty_state.dart';
import '../../theme/theme.dart';
import '../detail/detail_screen.dart';
import 'search_providers.dart';
import 'widgets/search_field.dart';
import 'widgets/search_result_row.dart';

/// `02 · 검색` 화면입니다. 검색창 + 결과 목록(또는 초기 · 결과 없음 상태)입니다.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: <Widget>[
        SearchField(),
        Expanded(child: _SearchBody()),
      ],
    );
  }
}

class _SearchBody extends ConsumerWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String query = ref.watch(searchQueryProvider).trim();
    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }

    final AsyncValue<List<Stock>> results = ref.watch(searchResultsProvider);
    final List<Stock>? stocks = results.value;

    if (results.hasError && !results.isLoading) {
      return _SearchError(onRetry: () => ref.invalidate(searchResultsProvider));
    }

    // 첫 조회 중(이전 결과 없음)에는 진행 표시만 보여줍니다.
    if (stocks == null) {
      return const _SearchingIndicator();
    }

    if (stocks.isEmpty && !results.isLoading) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: '검색 결과가 없습니다',
        // 검색어가 아주 길면 EmptyState가 4줄에서 말줄임 처리합니다.
        description: "'$query'와\n일치하는 검색 결과를 찾지 못했습니다.",
      );
    }

    return Column(
      children: <Widget>[
        if (results.isLoading) const _SearchingIndicator(compact: true),
        Expanded(
          child: ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: stocks.length,
            itemBuilder: (BuildContext context, int index) {
              final Stock stock = stocks[index];
              return SearchResultRow(
                stock: stock,
                query: query,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DetailScreen(stock: stock),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 검색 중 표시. 결과 영역 상단의 얇은 진행 막대입니다.
class _SearchingIndicator extends StatelessWidget {
  const _SearchingIndicator({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Widget bar = LinearProgressIndicator(
      minHeight: 2,
      color: colors.accentDefault,
      backgroundColor: Colors.transparent,
    );
    if (compact) return bar;
    return Align(alignment: Alignment.topCenter, child: bar);
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.wifi_off_rounded, size: 40, color: colors.textDisabled),
          SizedBox(height: dimens.space3),
          Text(
            '검색 결과를 불러오지 못했습니다',
            style: AppTextStyles.title.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: dimens.space3),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: colors.accentDefault),
            child: Text('다시 시도', style: AppTextStyles.label),
          ),
        ],
      ),
    );
  }
}
