import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/next_up_engine.dart';
import 'package:poker_analyzer/services/learning_path_unlock_engine.dart';
import 'package:poker_analyzer/services/lesson_progress_tracker_service.dart';
import 'package:poker_analyzer/services/track_mastery_service.dart';
import 'package:poker_analyzer/models/v3/lesson_track.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';

class _FakeUnlockEngine extends LearningPathUnlockEngine {
  final List<LessonTrack> tracks;
  _FakeUnlockEngine(this.tracks)
      : super(
          masteryService: TrackMasteryService(mastery: _DummyMasteryService()),
        );

  @override
  Future<List<LessonTrack>> getUnlockableTracks() async => tracks;
}

class _DummyMasteryService extends TagMasteryService {
  _DummyMasteryService()
      : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async => {};
}

class _FakeTrackMasteryService extends TrackMasteryService {
  final Map<String, double> map;
  _FakeTrackMasteryService(this.map) : super(mastery: _DummyMasteryService());

  @override
  Future<Map<String, double>> computeTrackMastery({bool force = false}) async =>
      map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
  });

  test('prefers track with lower mastery', () async {
    final tracks = [
      const LessonTrack(
        id: 't1',
        title: 'T1',
        description: '',
        stepIds: ['s1'],
      ),
      const LessonTrack(
        id: 't2',
        title: 'T2',
        description: '',
        stepIds: ['s2'],
      ),
    ];
    final unlock = _FakeUnlockEngine(tracks);
    final mastery = _FakeTrackMasteryService({'t1': 0.8, 't2': 0.2});
    final engine = NextUpEngine(unlockEngine: unlock, masteryService: mastery);
    final next = await engine.getNextRecommendedStep();
    expect(next?.trackId, 't2');
    expect(next?.stepId, 's2');
  });
}
