import 'package:flutter/material.dart';

import '../shared/widgets/app_toast.dart';
import '../theme/theme.dart';
import 'home_shell.dart';

class WatchlistApp extends StatelessWidget {
  const WatchlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '관심종목',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Navigator 위에 토스트를 얹어 검색 · 상세 어느 화면에서도 같은 자리에 뜨게 합니다.
      builder: (BuildContext context, Widget? child) =>
          ToastHost(child: child ?? const SizedBox.shrink()),
      home: const HomeShell(),
    );
  }
}
