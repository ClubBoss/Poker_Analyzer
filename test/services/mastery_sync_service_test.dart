import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mastery_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('merge blends values with weight', () {
    final service = MasterySyncService();
    final result = service.merge(
      current: {'a': 0.6},
      incoming: {'a': 1.0},
      incomingWeight: 0.5,
    );
    expect(result['a']!, closeTo(0.8, 0.0001));
  });

  test('missing current tag starts at 0.5', () {
    final service = MasterySyncService();
    final result = service.merge(
      current: const {},
      incoming: {'b': 0.2},
      incomingWeight: 0.5,
    );
    expect(result['b']!, closeTo(0.35, 0.0001));
  });

  test('missing incoming tag is untouched', () {
    final service = MasterySyncService();
    final result = service.merge(
      current: {'c': 0.3},
      incoming: const {},
      incomingWeight: 0.5,
    );
    expect(result['c'], 0.3);
  });
}
