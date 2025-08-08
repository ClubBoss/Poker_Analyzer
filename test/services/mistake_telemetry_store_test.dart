import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/mistake_telemetry_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records and persists error rates', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MistakeTelemetryStore();
    await store.recordMistake('push', weight: 0.2);
    await store.recordMistake('push', weight: 0.3);
    final rates = await store.getErrorRates();
    expect(rates['push'], closeTo(0.5, 0.001));
    final seen = await store.lastSeen('push');
    expect(seen, isNotNull);

    final store2 = MistakeTelemetryStore();
    final rates2 = await store2.getErrorRates();
    expect(rates2['push'], closeTo(0.5, 0.001));
  });
}
