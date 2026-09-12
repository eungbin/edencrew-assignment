import 'package:flutter/material.dart';

import '../domain/models/price_direction.dart';
import '../theme/app_colors.dart';

/// 등락 방향에 맞는 토큰 색을 고르는 도우미입니다. 상승 빨강, 하락 파랑, 보합 회색.
extension PriceColors on AppColors {
  Color priceText(PriceDirection direction) => switch (direction) {
    PriceDirection.up => priceUpText,
    PriceDirection.down => priceDownText,
    PriceDirection.flat => priceFlatText,
  };

  Color priceBg(PriceDirection direction) => switch (direction) {
    PriceDirection.up => priceUpBg,
    PriceDirection.down => priceDownBg,
    PriceDirection.flat => priceFlatBg,
  };

  Color chartLine(PriceDirection direction) => switch (direction) {
    PriceDirection.up => chartLineUp,
    PriceDirection.down => chartLineDown,
    PriceDirection.flat => chartLineFlat,
  };
}
