import 'dart:async';
import 'dart:collection';

/// 全域圖片載入協調器 — 節流 + 重試
class ImageLoadCoordinator {
  static final ImageLoadCoordinator _instance = ImageLoadCoordinator._();
  factory ImageLoadCoordinator() => _instance;
  ImageLoadCoordinator._();

  static const _maxConcurrent = 3;
  static const _requestDelay = Duration(milliseconds: 200);

  int _activeCount = 0;
  final Queue<_PendingLoad> _queue = Queue();

  Future<void> enqueue(void Function() startLoad) async {
    final completer = Completer<void>();
    _queue.add(_PendingLoad(startLoad, completer));
    _processQueue();
    return completer.future;
  }

  void _processQueue() {
    if (_activeCount >= _maxConcurrent || _queue.isEmpty) return;

    final request = _queue.removeFirst();
    _activeCount++;
    request.startLoad();
    request.completer.complete();

    Future.delayed(_requestDelay, _processQueue);
  }

  void notifyComplete() {
    _activeCount--;
    if (_activeCount < 0) _activeCount = 0;
    _processQueue();
  }
}

class _PendingLoad {
  final void Function() startLoad;
  final Completer<void> completer;
  _PendingLoad(this.startLoad, this.completer);
}
