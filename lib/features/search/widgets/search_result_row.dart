import 'package:flutter/material.dart';

import '../../../domain/models/stock.dart';
import '../../../shared/app_text_styles.dart';
import '../../../shared/widgets/favorite_button.dart';
import '../../../theme/theme.dart';
import 'highlighted_text.dart';

/// 검색 결과 한 행입니다. 종목명에서 검색어와 일치하는 부분을 강조합니다.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.stock,
    required this.query,
    required this.onTap,
  });

  final Stock stock;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Material(
      color: colors.surfaceBase,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space4,
            vertical: dimens.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.borderSubtle,
                width: dimens.borderHairline,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HighlightedText(
                      text: stock.name,
                      query: query,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                      ),
                      highlightColor: colors.searchHighlight,
                    ),
                    const SizedBox(height: 2),
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
