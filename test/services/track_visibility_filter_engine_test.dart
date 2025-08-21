import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/skill_level.dart';
import 'package:poker_analyzer/models/v3/lesson_track.dart';
import 'package:poker_analyzer/models/v3/track_unlock_condition.dart';
import 'package:poker_analyzer/services/track_visibility_filter_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profile = PlayerProfile(
    xp: 1500,
    tags: {'push_fold', 'icm'},
    gameType: GameType.tournament,
    skillLevel: SkillLevel.intermediate,
    completedLessonIds: {'intro'},
  );

  LessonTrack track(String id, TrackUnlockCondition? cond) => LessonTrack(
        id: id,
        title: id,
        description: '',
        stepIds: const ['lesson1'],
        unlockCondition: cond,
      );

  test('filters locked tracks', () async {
    final tracks = [
      track('a', const TrackUnlockCondition(minXp: 1000)),
      track('b', const TrackUnlockCondition(minXp: 2000)),
    ];
    final result = await const TrackVisibilityFilterEngine()
        .filterUnlockedTracks(tracks, profile);
    expect(result.map((t) => t.id), ['a']);
  });

  test('debug shows locked tracks', () async {
    final tracks = [
      track('a', const TrackUnlockCondition(minXp: 1000)),
      track('b', const TrackUnlockCondition(minXp: 2000)),
    ];
    final result = await const TrackVisibilityFilterEngine(
      showLockedTracks: true,
    ).filterUnlockedTracks(tracks, profile);
    expect(result.map((t) => t.id), ['a', 'b']);
  });
}
