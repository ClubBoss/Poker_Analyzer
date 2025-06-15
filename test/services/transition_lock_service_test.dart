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

  group('TransitionLockService.safeSetState', () {
    test('executes callback when mounted and not transitioning', () {
      final state = _MockState()..mountedFlag = true;
      final service = TransitionLockService();
      var counter = 0;
      service.safeSetState(state, () => counter++);
      expect(counter, 1);
      expect(state.setStateCalled, true);
    });

    test('skips callback when unmounted', () {
      final state = _MockState()..mountedFlag = false;
      final service = TransitionLockService();
      var counter = 0;
      service.safeSetState(state, () => counter++);
      expect(counter, 0);
      expect(state.setStateCalled, false);
    });

    test('skips callback when transitioning unless ignored', () {
      final state = _MockState();
      final service = TransitionLockService();
      service.boardTransitioning = true;
      var counter = 0;
      service.safeSetState(state, () => counter++);
      expect(counter, 0);
      expect(state.setStateCalled, false);

      service.safeSetState(state, () => counter++, ignoreTransitionLock: true);
      expect(counter, 1);
      expect(state.setStateCalled, true);
    });
  });
}
