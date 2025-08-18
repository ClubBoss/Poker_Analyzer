import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/training_session_fingerprint_logger_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logs start and end of sessions', () async {
    final service = TrainingSessionFingerprintLoggerService();
    await service.logSessionStart('pack1');
    await service.logSessionEnd('pack1', ['tag1', 'tag2']);

    final all = await service.getAllSessions();
    expect(all, hasLength(1));
    final fp = all.first;
    expect(fp.packId, 'pack1');
    expect(fp.tagsCovered, containsAll(['tag1', 'tag2']));
    expect(
      fp.endTime.isAfter(fp.startTime) || fp.endTime == fp.startTime,
      isTrue,
    );
  });

  test('clear removes all fingerprints', () async {
    final service = TrainingSessionFingerprintLoggerService();
    await service.logSessionStart('p');
    await service.logSessionEnd('p', []);
    await service.clear();
    final all = await service.getAllSessions();
    expect(all, isEmpty);
  });
}
