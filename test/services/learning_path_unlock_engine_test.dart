import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/v3/track_meta.dart';
import 'package:poker_analyzer/services/learning_path_unlock_engine.dart';
import 'package:poker_analyzer/services/track_mastery_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class FakeTagMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  FakeTagMasteryService(this._map)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

class FakeTrackMasteryService extends TrackMasteryService {
  final Map<String, double> _map;
  FakeTrackMasteryService(this._map)
    : super(mastery: FakeTagMasteryService(const {}));

  @override
  Future<Map<String, double>> computeTrackMastery({bool force = false}) async =>
      _map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearningPathUnlockEngine.clearCache();
  });

  test('track unlock requires prereq and streak', () async {
    final mastery = FakeTrackMasteryService({'mtt_pro': 0.6});
    final engine = LearningPathUnlockEngine(
      masteryService: mastery,
      streakRequirements: {'live_exploit': 2},
      prereq: {
        'live_exploit': ['mtt_pro'],
      },
      goalRequirements: const {},
      masteryRequirements: {
        'live_exploit': {'mtt_pro': 0.5},
      },
    );

    expect(await engine.canUnlockTrack('live_exploit'), isFalse);

    // mark prereq completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'lesson_track_meta_mtt_pro',
      jsonEncode(TrackMeta(completedAt: DateTime.now()).toJson()),
    );
    // not enough streak yet
    await prefs.setInt('lesson_streak_count', 1);
    await prefs.setString(
      'lesson_streak_last_day',
      DateTime.now().toIso8601String().split('T').first,
    );

    expect(await engine.canUnlockTrack('live_exploit'), isFalse);

    // satisfy streak
    await prefs.setInt('lesson_streak_count', 2);
    expect(await engine.canUnlockTrack('live_exploit'), isTrue);
  });
}
