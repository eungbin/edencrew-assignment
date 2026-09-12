import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/stock.dart';

/// 관심 목록과 정렬 기준을 로컬(SharedPreferences)에 저장합니다.
///
/// 저장 형식은 종목 메타(symbol · name · market)의 JSON 배열이라,
/// 앱을 다시 켰을 때 시세 없이도 목록을 즉시 그릴 수 있습니다.
class WatchlistStore {
  const WatchlistStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _watchlistKey = 'watchlist.v1';
  static const String _sortKey = 'watchlist.sort.v1';

  List<Stock> loadStocks() {
    final String? raw = _prefs.getString(_watchlistKey);
    if (raw == null || raw.isEmpty) return const <Stock>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return const <Stock>[];
      return decoded
          .whereType<Map<String, Object?>>()
          .map(Stock.fromJson)
          .toList(growable: false);
    } on FormatException {
      return const <Stock>[];
    }
  }

  Future<void> saveStocks(List<Stock> stocks) {
    final String raw = jsonEncode(
      stocks.map((Stock s) => s.toJson()).toList(growable: false),
    );
    return _prefs.setString(_watchlistKey, raw);
  }

  String? loadSortKey() => _prefs.getString(_sortKey);

  Future<void> saveSortKey(String key) => _prefs.setString(_sortKey, key);
}
