import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/stock.dart';

/// 검색창의 현재 입력값입니다.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;

  void clear() => state = '';
}

final NotifierProvider<SearchQueryNotifier, String> searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// 입력 디바운스 간격. 한글 조합 중 글자마다 요청이 나가지 않도록 300ms를 둡니다.
const Duration searchDebounce = Duration(milliseconds: 300);

/// 검색 결과입니다. 입력이 바뀌면 이전 요청은 버리고(디바운스) 새로 조회합니다.
///
/// 조회 중에는 `AsyncLoading`이지만 `value`에 직전 결과가 남아 있어
/// 화면은 이전 목록을 유지한 채 상단에만 진행 표시를 보여줍니다.
final searchResultsProvider = FutureProvider.autoDispose<List<Stock>>((
  Ref ref,
) async {
  final String query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const <Stock>[];

  bool disposed = false;
  ref.onDispose(() => disposed = true);
  await Future<void>.delayed(searchDebounce);
  // 대기 중에 입력이 또 바뀌었으면 이 인스턴스는 이미 폐기된 상태입니다.
  if (disposed) return const <Stock>[];

  return ref.read(stockRepositoryProvider).search(query);
});
