import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/training_session_fingerprint_recorder.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records and checks completion', () async {
    final recorder = TrainingSessionFingerprintRecorder.instance;
    const fp = 'abc123';

    expect(await recorder.isCompleted(fp), isFalse);
    await recorder.recordCompletion(fp);
    expect(await recorder.isCompleted(fp), isTrue);
    expect(await recorder.getAllFingerprints(), [fp]);
  });

  test('does not duplicate fingerprints', () async {
    final recorder = TrainingSessionFingerprintRecorder.instance;
    const fp = 'xyz';

    await recorder.recordCompletion(fp);
    await recorder.recordCompletion(fp);
    final all = await recorder.getAllFingerprints();
    expect(all, [fp]);
  });
}
