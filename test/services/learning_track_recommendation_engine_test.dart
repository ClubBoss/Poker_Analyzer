import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/v3/track_meta.dart';
import 'package:poker_analyzer/services/learning_track_recommendation_engine.dart';
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

  test('getRecommendedTracks sorts by mastery and filters completed', () async {
    SharedPreferences.setMockInitialValues({
      'lesson_track_meta_leak_fixer': jsonEncode(
        TrackMeta(completedAt: DateTime.now()).toJson(),
      ),
    });

    final mastery = FakeTrackMasteryService({
      'mtt_pro': 0.2,
      'live_exploit': 0.8,
      'leak_fixer': 0.1,
      'yaml_sample': 0.5,
    });

    final engine = LearningTrackRecommendationEngine(masteryService: mastery);
    final list = await engine.getRecommendedTracks();
    expect(list.map((e) => e.id).toList(), [
      'mtt_pro',
      'yaml_sample',
      'live_exploit',
    ]);
  });
}
