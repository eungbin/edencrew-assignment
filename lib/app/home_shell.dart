import 'package:flutter/material.dart';

import '../features/search/search_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../shared/widgets/app_tab_bar.dart';

/// 관심 / 검색 탭을 담는 셸입니다.
///
/// `IndexedStack`으로 두 화면을 모두 살려 두어 탭을 오가도 검색어 · 스크롤 위치가 유지됩니다.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const <Widget>[WatchlistScreen(), SearchScreen()],
        ),
      ),
      bottomNavigationBar: AppTabBar(
        currentIndex: _index,
        onSelected: (int index) {
          if (index != _index) FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _index = index);
        },
      ),
    );
  }
}
