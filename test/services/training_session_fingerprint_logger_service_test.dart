import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/training_session_fingerprint_logger_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logs and retrieves sessions', () async {
    final service = TrainingSessionFingerprintLoggerService();
    final session = TrainingSessionFingerprint(
      packId: 'pack1',
      tags: const ['tag1', 'tag2'],
      totalSpots: 5,
      correct: 3,
      incorrect: 2,
      completedAt: DateTime(2023, 1, 1),
    );
    await service.logSession(session);

    final all = await service.getAll();
    expect(all, hasLength(1));
    expect(all.first.packId, 'pack1');
    expect(all.first.tags, containsAll(['tag1', 'tag2']));
    expect(all.first.totalSpots, 5);
    expect(all.first.correct, 3);
    expect(all.first.incorrect, 2);
    expect(all.first.completedAt, DateTime(2023, 1, 1));
  });

  test('clear removes all fingerprints', () async {
    final service = TrainingSessionFingerprintLoggerService();
    await service.logSession(TrainingSessionFingerprint(packId: 'p'));
    await service.clear();
    final all = await service.getAll();
    expect(all, isEmpty);
  });
}
