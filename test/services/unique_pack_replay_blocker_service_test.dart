import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_pack_fingerprint_generator.dart';
import 'package:poker_analyzer/services/training_session_fingerprint_recorder.dart';
import 'package:poker_analyzer/services/unique_pack_replay_blocker_service.dart';

void main() {
  late UniquePackReplayBlockerService blocker;
  late TrainingPackTemplateV2 pack;
  const gen = TrainingPackFingerprintGenerator();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    blocker = UniquePackReplayBlockerService();
    pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      trainingType: TrainingType.quiz,
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      spotCount: 1,
    );
  });

  test('returns false when blocking disabled', () async {
    expect(await blocker.isReplayBlocked(pack), isFalse);
  });

  test('does not block when enabled but pack not completed', () async {
    await blocker.setBlockingEnabled(true);
    expect(await blocker.isReplayBlocked(pack), isFalse);
  });

  test('blocks replay when enabled and completed', () async {
    await blocker.setBlockingEnabled(true);
    final fp = gen.generate(pack);
    await TrainingSessionFingerprintRecorder.instance.recordCompletion(fp);
    expect(await blocker.isReplayBlocked(pack), isTrue);
  });
}

