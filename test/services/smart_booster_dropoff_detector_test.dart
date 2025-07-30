import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_booster_dropoff_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects dropoff when fails dominate recent outcomes', () async {
    SharedPreferences.setMockInitialValues({});
    final detector = SmartBoosterDropoffDetector.instance;
    for (var i = 0; i < 3; i++) {
      await detector.recordOutcome('failed');
    }
    for (var i = 0; i < 2; i++) {
      await detector.recordOutcome('completed');
    }
    expect(await detector.isInDropoffState(), true);
  });

  test('no dropoff with few failures', () async {
    SharedPreferences.setMockInitialValues({});
    final detector = SmartBoosterDropoffDetector.instance;
    await detector.recordOutcome('failed');
    await detector.recordOutcome('completed');
    await detector.recordOutcome('failed');
    await detector.recordOutcome('completed');
    await detector.recordOutcome('completed');
    expect(await detector.isInDropoffState(), false);
  });
}
