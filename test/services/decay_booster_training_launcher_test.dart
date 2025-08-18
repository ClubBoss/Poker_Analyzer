import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/decay_booster_training_launcher.dart';
import 'package:poker_analyzer/services/booster_queue_service.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/user_action_logger.dart';

class _FakeLauncher extends TrainingSessionLauncher {
  TrainingPackTemplateV2? launched;
  _FakeLauncher() : super();
  @override
  Future<void> launch(
    TrainingPackTemplateV2 template, {
    int startIndex = 0,
    List<String>? sessionTags,
  }) async {
    launched = template;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserActionLogger.instance.load();
    BoosterQueueService.instance.clear();
  });

  test('launch opens session and clears queue', () async {
    final spot = TrainingPackSpot(id: 's1');
    await BoosterQueueService.instance.addSpots([spot]);
    final launcher = _FakeLauncher();
    final service = DecayBoosterTrainingLauncher(launcher: launcher);
    await service.launch();
    expect(launcher.launched?.spots.length, 1);
    expect(BoosterQueueService.instance.getQueue(), isEmpty);
    expect(
      UserActionLogger.instance.events.last['event'],
      'decay_booster_completed',
    );
  });
}
