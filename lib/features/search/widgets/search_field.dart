import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_text_styles.dart';
import '../../../theme/theme.dart';
import '../search_providers.dart';

/// 검색 입력창입니다. 시안: 바깥 여백 8/16/12/16, 높이 40, 라운드 8,
/// 테두리 border/strong, 배경 surface/sunken, 안쪽 패딩 10/12, 요소 간격 8.
class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.space2,
        dimens.space4,
        dimens.space3,
      ),
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: dimens.space3),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
          border: Border.all(
            color: colors.borderStrong,
            width: dimens.borderHairline,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.search_rounded,
              size: dimens.iconMd,
              color: colors.textTertiary,
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: ref.read(searchQueryProvider.notifier).set,
                textInputAction: TextInputAction.search,
                cursorColor: colors.accentDefault,
                style: AppTextStyles.body.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '종목명 또는 종목코드',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
            SizedBox(width: dimens.space2),
            Semantics(
              button: true,
              label: '검색어 지우기',
              child: InkResponse(
                radius: dimens.space4,
                onTap: _clear,
                child: Icon(
                  Icons.close_rounded,
                  size: dimens.iconSm,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
