import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_session_fingerprint_logger_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logs and retrieves sessions', () async {
    final service = TrainingSessionFingerprintLoggerService();
    final session = TrainingSessionFingerprint(
      fingerprint: 'abc',
      packId: 'pack1',
      trainingType: TrainingType.pushFold,
      spotCount: 5,
      accuracy: 0.8,
      completedAt: DateTime(2023, 1, 1),
    );
    await service.logSession(session);

    final all = await service.getAll();
    expect(all, hasLength(1));
    expect(all.first.fingerprint, 'abc');
    expect(all.first.packId, 'pack1');
    expect(all.first.trainingType, TrainingType.pushFold);
    expect(all.first.spotCount, 5);
    expect(all.first.accuracy, closeTo(0.8, 0.0001));
    expect(all.first.completedAt, DateTime(2023, 1, 1));
  });
}
