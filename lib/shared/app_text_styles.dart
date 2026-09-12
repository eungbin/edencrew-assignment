import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Figma 텍스트 스타일(title · display · body · label · caption)의 크기와 행간입니다.
///
/// 토큰(`lib/theme`)은 서체와 굵기만 정의하므로, 크기 · 행간 · 자간은
/// 시안의 텍스트 레이어에서 읽은 값을 여기에 모아 두고 화면에서 재사용합니다.
/// 색상은 포함하지 않습니다. 색은 항상 `context.colors.*`로 입힙니다.
abstract final class AppTextStyles {
  /// Figma는 숫자에 별도의 숫자 전용 서체 변수를 씁니다. 저장소에는 Noto Sans KR만
  /// 제공되므로 같은 서체에 고정폭 숫자(tabular figures)만 켜서 자릿수가 흔들리지 않게 합니다.
  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const TextStyle _base = TextStyle(
    fontFamily: AppTypography.fontFamily,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 화면 제목, 빈 상태 제목: 19 / 22 Bold
  static final TextStyle title = _base.copyWith(
    fontSize: 19,
    height: 22 / 19,
    fontWeight: AppTypography.bold,
    letterSpacing: -0.2,
  );

  /// 상세 화면 현재가: 30 / 36 Bold
  static final TextStyle display = _base.copyWith(
    fontSize: 30,
    height: 36 / 30,
    fontWeight: AppTypography.bold,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );

  /// 종목명, 현재가, 목록 본문: 15 / 20 Medium
  static final TextStyle body = _base.copyWith(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: AppTypography.medium,
    letterSpacing: -0.1,
  );

  static final TextStyle bodyNum = body.copyWith(fontFeatures: _tabular);

  /// 정렬 칩, 토스트, 섹션 제목: 13 / 18 Bold
  static final TextStyle label = _base.copyWith(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: AppTypography.bold,
  );

  /// 기간 탭: 13 / 18 Regular
  static final TextStyle chip = _base.copyWith(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: AppTypography.regular,
  );

  /// 종목코드 · 시장, 등락, 탭 라벨, 표: 11 / 14 Regular
  static final TextStyle caption = _base.copyWith(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: AppTypography.regular,
  );

  static final TextStyle captionNum = caption.copyWith(fontFeatures: _tabular);
}
