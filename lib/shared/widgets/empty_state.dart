import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../app_text_styles.dart';

/// 관심 없음 · 검색 전 · 검색 결과 없음에 공통으로 쓰는 빈 상태입니다.
///
/// 시안 구조: 아이콘 40 / 간격 12 / 제목 19 Bold(text/secondary) / 간격 12 /
/// 안내 문구 11/14(text/tertiary, 가운데 정렬), 목록 영역 세로 중앙.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: colors.textDisabled),
            SizedBox(height: dimens.space3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: dimens.space3),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
