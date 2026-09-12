import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma 시안에서 내보낸 아이콘 SVG 경로입니다. (`assets/icons/`)
///
/// 파일 이름 뒤의 숫자는 시안에서 그 아이콘이 쓰인 크기입니다. 같은 모양이라도
/// 크기별로 선 굵기 비율이 달라 시안에 있는 크기는 각각 따로 내보냈습니다.
abstract final class AppIcons {
  static const String _dir = 'assets/icons';

  static const String align = '$_dir/align.svg';
  static const String back = '$_dir/back.svg';
  static const String bellPlus = '$_dir/bell_plus.svg';
  static const String check = '$_dir/check.svg';
  static const String plus = '$_dir/plus.svg';
  static const String refresh = '$_dir/refresh.svg';
  static const String search16 = '$_dir/search_16.svg';
  static const String search22 = '$_dir/search_22.svg';
  static const String search40 = '$_dir/search_40.svg';
  static const String searchEmpty40 = '$_dir/search_empty_40.svg';
  static const String star22 = '$_dir/star_22.svg';
  static const String star40 = '$_dir/star_40.svg';
  static const String starFill22 = '$_dir/star_fill_22.svg';
  static const String x = '$_dir/x.svg';
}

/// SVG 아이콘을 시맨틱 색 토큰으로 칠해 그립니다.
///
/// SVG 파일 안의 색은 시안 기본값일 뿐이고, 실제 색은 항상 [color]로 덮어씁니다.
/// 그래야 상태(관심 등록 여부, 탭 활성 여부)에 따라 토큰 색을 바꿔 쓸 수 있습니다.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.asset, {
    super.key,
    required this.size,
    required this.color,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
