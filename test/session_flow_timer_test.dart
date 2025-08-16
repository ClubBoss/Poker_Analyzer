import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

// TODO: replace helper logic with SessionFlowTimer public API when available.

int _clampDelay(int? ms) {
  final delay = ms ?? 600;
  if (delay < 300) return 300;
  if (delay > 800) return 800;
  return delay;
}

class _SessionFlowTimer {
  final int delayMs;
  Timer? _timer;
  final void Function() onFire;
  _SessionFlowTimer({required this.delayMs, required this.onFire});

  void start() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delayMs), onFire);
  }
}

void main() {
  group('SessionFlowTimer', () {
    test('auto-next delay respects bounds', () {
      expect(_clampDelay(null), 600);
      expect(_clampDelay(100), 300);
      expect(_clampDelay(900), 800);
    });

    test('debounce works', () {
      fakeAsync((async) {
        var count = 0;
        final timer = _SessionFlowTimer(delayMs: 300, onFire: () => count++);
        timer.start();
        async.elapse(const Duration(milliseconds: 150));
        timer.start();
        async.elapse(const Duration(milliseconds: 299));
        expect(count, 0);
        async.elapse(const Duration(milliseconds: 1));
        expect(count, 1);
        timer.start();
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 2);
      });
    });
  });
}
