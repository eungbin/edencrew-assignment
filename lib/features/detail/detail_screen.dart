import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../domain/models/daily_price.dart';
import '../../domain/models/price_direction.dart';
import '../../domain/models/quote.dart';
import '../../domain/models/stock.dart';
import '../../shared/app_text_styles.dart';
import '../../shared/price_colors.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/favorite_button.dart';
import '../../shared/widgets/skeleton_box.dart';
import '../../theme/theme.dart';
import 'detail_providers.dart';
import 'widgets/candle_chart.dart';
import 'widgets/daily_price_table.dart';
import 'widgets/period_chips.dart';
import 'widgets/quote_summary.dart';

/// `03 · 종목상세` 화면입니다.
///
/// 구조(시안): 앱바 55 / 본문 패딩 14·16·16·16, 섹션 간격 24
/// - Price 블록(간격 16): 현재가 행 → 기간 탭 → 캔들 차트(200) → 요약 카드
/// - Daily 블록(간격 4): `일별 시세` 제목 → 표(헤더 32 + 행 32)
class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.stock});

  /// 목록에서 넘어온 종목. 메타 응답이 오기 전까지 헤더에 먼저 보여줍니다.
  final Stock stock;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  ChartPeriod _period = ChartPeriod.month1;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final String symbol = widget.stock.symbol;

    final Stock stock =
        ref.watch(stockInfoProvider(symbol)).value ?? widget.stock;
    final AsyncValue<Quote?> quote = ref.watch(stockQuoteProvider(symbol));
    final DailyPricesKey dailyKey = (symbol: symbol, period: _period);
    final AsyncValue<List<DailyPrice>> daily = ref.watch(
      dailyPricesProvider(dailyKey),
    );

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Column(
        children: <Widget>[
          _DetailAppBar(stock: stock),
          Expanded(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    dimens.space4,
                    14,
                    dimens.space4,
                    0,
                  ),
                  sliver: SliverList.list(
                    children: <Widget>[
                      _CurrentPrice(quote: quote),
                      SizedBox(height: dimens.space4),
                      PeriodChips(
                        selected: _period,
                        onSelected: (ChartPeriod p) =>
                            setState(() => _period = p),
                      ),
                      SizedBox(height: dimens.space4),
                      _ChartSection(
                        daily: daily,
                        onRetry: () =>
                            ref.invalidate(dailyPricesProvider(dailyKey)),
                      ),
                      SizedBox(height: dimens.space4),
                      QuoteSummary(quote: quote),
                      SizedBox(height: dimens.space6),
                      Text(
                        '일별 시세',
                        style: AppTextStyles.label.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: dimens.space1),
                      const DailyPriceHeader(),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    dimens.space4,
                    0,
                    dimens.space4,
                    dimens.space4 + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: DailyPriceRows(daily: daily),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space4,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              Semantics(
                button: true,
                label: '뒤로 가기',
                child: InkResponse(
                  radius: dimens.space5,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: AppSvgIcon(
                    AppIcons.back,
                    size: dimens.iconMd,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: dimens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stock.label,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: dimens.space3),
              FavoriteButton(stock: stock),
            ],
          ),
        ),
      ),
    );
  }
}

/// 현재가 + 전일 대비 등락(▲ / ▼). 시세가 오기 전에는 스켈레톤을 둡니다.
class _CurrentPrice extends StatelessWidget {
  const _CurrentPrice({required this.quote});

  final AsyncValue<Quote?> quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final Quote? q = quote.value;

    if (q == null) {
      if (quote.hasError) {
        return SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '현재가를 불러오지 못했습니다.',
              style: AppTextStyles.body.copyWith(color: colors.textTertiary),
            ),
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          const SkeletonBox(width: 114, height: 36),
          SizedBox(width: dimens.space2),
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: SkeletonBox(width: 96, height: 20),
          ),
        ],
      );
    }

    final PriceDirection direction = q.direction;
    final String arrow = switch (direction) {
      PriceDirection.up => '▲ ',
      PriceDirection.down => '▼ ',
      PriceDirection.flat => '',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          Formatters.number(q.price),
          style: AppTextStyles.display.copyWith(color: colors.textPrimary),
        ),
        SizedBox(width: dimens.space2),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '$arrow${Formatters.number(q.change.abs())} '
            '(${Formatters.signedPercent(q.changeRate)})',
            style: AppTextStyles.bodyNum.copyWith(
              color: colors.priceText(direction),
            ),
          ),
        ),
      ],
    );
  }
}

/// 차트 영역. 로딩 중 스켈레톤, 실패 시 재시도 버튼, 성공 시 캔들 차트입니다.
class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.daily, required this.onRetry});

  final AsyncValue<List<DailyPrice>> daily;
  final VoidCallback onRetry;

  static const double height = 200;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final List<DailyPrice>? prices = daily.value;

    if (prices != null && prices.isNotEmpty) {
      return SizedBox(
        height: height,
        child: CandleChart(prices: prices),
      );
    }
    if (daily.hasError && !daily.isLoading) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '일별 시세를 불러오지 못했습니다.',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: colors.accentDefault,
                ),
                child: Text('다시 시도', style: AppTextStyles.label),
              ),
            ],
          ),
        ),
      );
    }
    if (prices != null && prices.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '표시할 시세가 없습니다.',
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          SkeletonBox(
            width: constraints.maxWidth,
            height: height,
            radius: context.dimens.radiusMd,
          ),
    );
  }
}
