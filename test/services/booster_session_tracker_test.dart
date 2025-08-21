import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_session_tracker.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackTemplateV2 tpl(String id, String tag) => TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.theory,
    tags: [tag],
    spots: const [],
    spotCount: 0,
    created: DateTime.now(),
    gameType: GameType.tournament,
    positions: const [],
    meta: const {},
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks booster usage and updates profile', () async {
    final booster = tpl('b1', 'cbet');
    final profile = PlayerProfile(tagAccuracy: {'cbet': 0.5});
    final tracker = BoosterSessionTracker.instance;

    var stats = await tracker.trackSession(
      booster,
      profile,
      now: DateTime(2024, 1, 1),
    );

    expect(profile.boosterCompletions['cbet'], 1);
    expect(profile.tagAccuracy['cbet']!, closeTo(0.55, 0.0001));
    expect(profile.boosterStreak, 1);
    expect(stats.totalCompleted, 1);

    stats = await tracker.trackSession(
      booster,
      profile,
      now: DateTime(2024, 1, 2),
    );

    expect(profile.boosterCompletions['cbet'], 2);
    expect(profile.tagAccuracy['cbet']!, closeTo(0.6, 0.0001));
    expect(profile.boosterStreak, 2);
    expect(stats.streak, 2);
  });
}
