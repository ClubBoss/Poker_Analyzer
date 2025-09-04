// Pure Dart tests for live telemetry helper

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live.dart';
import 'package:poker_analyzer/live/live_telemetry.dart';

void main() {
  setUp(() {
    // Ensure deterministic starting mode
    LiveRuntime.setMode(TrainingMode.online);
  });

  test('default mode is online in props', () {
    final props = buildLiveViolationProps(
      moduleId: 'm1',
      violation: const LiveViolation('code_a', 'Message A'),
    );
    expect(props.containsKey('mode'), isTrue);
    expect(props['mode'], equals('online'));
  });

  test('toggling to live sets mode==live', () {
    LiveRuntime.toggle();
    final props = buildLiveViolationProps(
      moduleId: 'm2',
      violation: const LiveViolation('code_b', 'Message B'),
    );
    expect(props['mode'], equals('live'));
  });

  test('moduleId and code are preserved', () {
    final v = const LiveViolation('string_bet_call_only', 'X');
    final props = buildLiveViolationProps(moduleId: 'mod-123', violation: v);
    expect(props['moduleId'], equals('mod-123'));
    expect(props['code'], equals('string_bet_call_only'));
  });
}
