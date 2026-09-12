import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 토스트 종류. 아이콘과 문구는 [ToastHost]가 종류에 맞춰 그립니다.
enum ToastKind { favoriteAdded, favoriteRemoved }

class ToastMessage {
  const ToastMessage({required this.id, required this.kind});

  /// 같은 종류의 토스트를 연달아 띄워도 새 애니메이션이 돌도록 구분하는 값입니다.
  final int id;
  final ToastKind kind;
}

/// 화면 하단 토스트 상태입니다. 한 번에 하나만 보여주고, 새 토스트가 오면 교체합니다.
///
/// 노출 시간은 2초입니다. 관심 등록/해제처럼 짧은 확인 메시지는
/// 읽는 데 1초면 충분하고, 연타했을 때 화면에 오래 남지 않는 편이 낫다고 판단했습니다.
class ToastNotifier extends Notifier<ToastMessage?> {
  static const Duration duration = Duration(seconds: 2);

  Timer? _timer;
  int _sequence = 0;

  @override
  ToastMessage? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(ToastKind kind) {
    _timer?.cancel();
    state = ToastMessage(id: ++_sequence, kind: kind);
    _timer = Timer(duration, () {
      if (ref.mounted) state = null;
    });
  }

  void dismiss() {
    _timer?.cancel();
    state = null;
  }
}

final NotifierProvider<ToastNotifier, ToastMessage?> toastProvider =
    NotifierProvider<ToastNotifier, ToastMessage?>(ToastNotifier.new);
