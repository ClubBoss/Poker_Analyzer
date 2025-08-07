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
      TrainingSessionFingerprint(packId: '1', tagsCovered: const ['a', 'b']),
    );
    await logger.logSession(
      TrainingSessionFingerprint(packId: '2', tagsCovered: const ['b']),
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
      TrainingSessionFingerprint(packId: '1', tagsCovered: const ['x']),
    );
    await logger.logSession(
      TrainingSessionFingerprint(packId: '2', tagsCovered: const ['x', 'y']),
    );
    await logger.logSession(
      TrainingSessionFingerprint(packId: '3', tagsCovered: const ['y', 'z']),
    );
    final tracker = SkillTagSessionCoverageTrackerService(logger: logger);
    final low = await tracker.lowFrequencyTags(2);
    expect(low, contains('z'));
    expect(low, isNot(contains('x')));
    expect(low, isNot(contains('y')));
  });

  test('updateCoverageMap persists aggregated counts', () async {
    final logger = TrainingSessionFingerprintLoggerService();
    await logger.logSession(
      TrainingSessionFingerprint(packId: '1', tagsCovered: const ['a', 'b']),
    );
    await logger.logSession(
      TrainingSessionFingerprint(packId: '2', tagsCovered: const ['b']),
    );
    final tracker = SkillTagSessionCoverageTrackerService(logger: logger);
    await tracker.updateCoverageMap();
    final map = await tracker.getCoverageMap();
    expect(map['a'], 1);
    expect(map['b'], 2);
  });

  test('clearCoverageMap removes stored coverage', () async {
    final logger = TrainingSessionFingerprintLoggerService();
    await logger.logSession(
      TrainingSessionFingerprint(packId: '1', tagsCovered: const ['a']),
    );
    final tracker = SkillTagSessionCoverageTrackerService(logger: logger);
    await tracker.updateCoverageMap();
    await tracker.clearCoverageMap();
    final map = await tracker.getCoverageMap();
    expect(map, isEmpty);
  });
}
