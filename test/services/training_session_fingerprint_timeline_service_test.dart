import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/training_session_fingerprint_logger_service.dart';
import 'package:poker_analyzer/services/training_session_fingerprint_timeline_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('generateTimeline aggregates sessions by day', () async {
    final logger = TrainingSessionFingerprintLoggerService();
    await logger.logSession(TrainingSessionFingerprint(
      packId: 'p1',
      tags: const ['a'],
      completedAt: DateTime(2023, 1, 1, 10),
      totalSpots: 5,
      correct: 3,
      incorrect: 2,
    ));
    await logger.logSession(TrainingSessionFingerprint(
      packId: 'p2',
      tags: const ['b'],
      completedAt: DateTime(2023, 1, 1, 15),
      totalSpots: 2,
      correct: 1,
      incorrect: 1,
    ));
    await logger.logSession(TrainingSessionFingerprint(
      packId: 'p3',
      tags: const ['a', 'c'],
      completedAt: DateTime(2023, 1, 2),
      totalSpots: 5,
      correct: 5,
      incorrect: 0,
    ));

    final service = TrainingSessionFingerprintTimelineService(logger: logger);
    final timeline = await service.generateTimeline();

    expect(timeline, hasLength(2));
    expect(timeline[0].date, DateTime(2023, 1, 1));
    expect(timeline[0].sessionCount, 2);
    expect(timeline[0].avgAccuracy, closeTo(4 / 7, 1e-9));
    expect(timeline[0].tags, {'a', 'b'});

    expect(timeline[1].date, DateTime(2023, 1, 2));
    expect(timeline[1].sessionCount, 1);
    expect(timeline[1].avgAccuracy, 1.0);
    expect(timeline[1].tags, {'a', 'c'});
  });
}
