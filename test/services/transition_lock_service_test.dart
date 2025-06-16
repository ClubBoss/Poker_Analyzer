import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:poker_ai_analyzer/services/transition_lock_service.dart';

class _MockWidget extends StatefulWidget {
  const _MockWidget();

  @override
  State<_MockWidget> createState() => _MockState();
}

class _MockState extends State<_MockWidget> {
  bool mountedFlag = true;
  bool setStateCalled = false;

  @override
  bool get mounted => mountedFlag;

  @override
  void setState(VoidCallback fn) {
    setStateCalled = true;
    fn();
  }

  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TransitionLockService service;
  late _MockState state;

  setUp(() {
    service = TransitionLockService();
    state = _MockState();
  });

  group('TransitionLockService.safeSetState', () {
    test('executes callback when mounted and not transitioning', () {
      state.mountedFlag = true;
      var counter = 0;
      service.safeSetState(state, () => counter++);
      expect(counter, 1);
      expect(state.setStateCalled, isTrue);
    });

    test('skips callback when unmounted', () {
      state.mountedFlag = false;
      var counter = 0;
      service.safeSetState(state, () => counter++);
      expect(counter, 0);
      expect(state.setStateCalled, isFalse);
    });

    test('skips callback when transitioning unless ignored', () {
      service.boardTransitioning = true;
      var counter = 0;
      service.safeSetState(state, () => counter++);
      expect(counter, 0);
      expect(state.setStateCalled, isFalse);

      service.safeSetState(state, () => counter++, ignoreTransitionLock: true);
      expect(counter, 1);
      expect(state.setStateCalled, isTrue);
    });
  });

  group('manual locking', () {
    test('lock and unlock toggle isLocked', () {
      expect(service.isLocked, isFalse);
      service.lock();
      expect(service.isLocked, isTrue);
      service.unlock();
      expect(service.isLocked, isFalse);
    });
  });
}
