import 'package:test/test.dart';

import 'package:poker_analyzer/telemetry/telemetry.dart';
import 'package:poker_analyzer/live/live_runtime.dart';
import 'package:poker_analyzer/live/live_mode.dart';

void main() {
  setUp(() {
    // Ensure a stable default for each test.
    LiveRuntime.setMode(TrainingMode.online);
  });

  test('default online mode tag', () {
    final tagged = withMode({});
    expect(tagged['mode'], equals('online'));
  });

  test('toggle live/online updates mode tag', () {
    LiveRuntime.toggle();
    expect(withMode({})['mode'], equals('live'));

    LiveRuntime.toggle();
    expect(withMode({})['mode'], equals('online'));
  });

  test('withMode preserves keys and does not mutate input', () {
    final input = <String, Object?>{'a': 1};
    final output = withMode(input);
    expect(output['a'], equals(1));
    expect(output['mode'], equals('online'));
    // Input should remain unchanged.
    expect(input.containsKey('mode'), isFalse);
    expect(input['a'], equals(1));
  });

  test('withMode overrides existing mode to current tag', () {
    final input = <String, Object?>{'mode': 'live'};
    // Currently online (from setUp).
    final output = withMode(input);
    expect(output['mode'], equals('online'));
  });
}
