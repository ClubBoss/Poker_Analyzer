import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/skill_tag_session_coverage_tracker_service.dart';
import 'package:poker_analyzer/services/training_session_fingerprint_logger_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computeCoverage counts tags correctly', () async {
    final logger = TrainingSessionFingerprintLoggerService();
    await logger.logSession(
      TrainingSessionFingerprint(packId: '1', tags: const ['a', 'b']),
    );
    await logger.logSession(
      TrainingSessionFingerprint(packId: '2', tags: const ['b']),
    );
    final tracker = SkillTagSessionCoverageTrackerService(logger: logger);
    final coverage = await tracker.computeCoverage();
    expect(coverage['a'], 1);
    expect(coverage['b'], 2);
    expect(coverage.containsKey('c'), isFalse);
  });

  test('lowFrequencyTags returns tags under threshold', () async {
    final logger = TrainingSessionFingerprintLoggerService();
    await logger.logSession(
      TrainingSessionFingerprint(packId: '1', tags: const ['x']),
    );
    await logger.logSession(
      TrainingSessionFingerprint(packId: '2', tags: const ['x', 'y']),
    );
    await logger.logSession(
      TrainingSessionFingerprint(packId: '3', tags: const ['y', 'z']),
    );
    final tracker = SkillTagSessionCoverageTrackerService(logger: logger);
    final low = await tracker.lowFrequencyTags(2);
    expect(low, contains('z'));
    expect(low, isNot(contains('x')));
    expect(low, isNot(contains('y')));
  });
}
