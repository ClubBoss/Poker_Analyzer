import '../models/v3/lesson_track.dart';
import 'learning_track_engine.dart';
import 'yaml_lesson_track_loader.dart';
import 'track_mastery_service.dart';
import 'lesson_goal_streak_engine.dart';
import 'lesson_goal_engine.dart';
import 'lesson_streak_engine.dart';
import 'lesson_track_meta_service.dart';

class LearningPathUnlockEngine {
  final TrackMasteryService masteryService;
  final LessonGoalEngine goalEngine;
  final LessonStreakEngine streakEngine;
  final LessonTrackMetaService metaService;
  final LearningTrackEngine trackEngine;
  final YamlLessonTrackLoader yamlLoader;

  LearningPathUnlockEngine({
    required this.masteryService,
    LessonGoalEngine? goalEngine,
    LessonStreakEngine? streakEngine,
    LessonTrackMetaService? metaService,
    LearningTrackEngine trackEngine = const LearningTrackEngine(),
    YamlLessonTrackLoader? yamlLoader,
    Map<String, List<String>>? prereq,
    Map<String, int>? streakRequirements,
    Map<String, int>? goalRequirements,
    Map<String, Map<String, double>>? masteryRequirements,
  })  : goalEngine = goalEngine ?? LessonGoalEngine.instance,
        streakEngine = streakEngine ?? LessonStreakEngine.instance,
        metaService = metaService ?? LessonTrackMetaService.instance,
        trackEngine = trackEngine,
        yamlLoader = yamlLoader ?? YamlLessonTrackLoader.instance,
        _prereq = prereq ?? const {
          'live_exploit': ['mtt_pro'],
          'leak_fixer': ['live_exploit'],
        },
        _streakReq = streakRequirements ?? const {
          'leak_fixer': 3,
        },
        _goalReq = goalRequirements ?? const {},
        _masteryReq = masteryRequirements ?? const {
          'live_exploit': {'mtt_pro': 0.5},
          'leak_fixer': {'live_exploit': 0.6},
        };

  final Map<String, List<String>> _prereq;
  final Map<String, int> _streakReq;
  final Map<String, int> _goalReq;
  final Map<String, Map<String, double>> _masteryReq;

  static final Map<String, bool> _cache = {};
  static List<LessonTrack>? _cachedList;
  static DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  static void clearCache() {
    _cache.clear();
    _cachedList = null;
    _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<bool> canUnlockTrack(String trackId) async {
    if (_cache.containsKey(trackId)) return _cache[trackId]!;

    bool ok = true;

    final meta = await metaService.load(trackId);
    if (meta?.completedAt != null) ok = false;

    final prereq = _prereq[trackId];
    if (ok && prereq != null) {
      for (final id in prereq) {
        final m = await metaService.load(id);
        if (m?.completedAt == null) {
          ok = false;
          break;
        }
      }
    }

    final masteryReq = _masteryReq[trackId];
    if (ok && masteryReq != null) {
      final mastery = await masteryService.computeTrackMastery();
      for (final entry in masteryReq.entries) {
        final value = mastery[entry.key] ?? 0.0;
        if (value < entry.value) {
          ok = false;
          break;
        }
      }
    }

    final streakReq = _streakReq[trackId];
    if (ok && streakReq != null) {
      final streak = await streakEngine.getCurrentStreak();
      if (streak < streakReq) ok = false;
    }

    final goalReq = _goalReq[trackId];
    if (ok && goalReq != null) {
      final count = await LessonGoalStreakEngine.instance.getCurrentStreak();
      if (count < goalReq) ok = false;
    }

    _cache[trackId] = ok;
    return ok;
  }

  Future<List<LessonTrack>> getUnlockableTracks() async {
    final now = DateTime.now();
    if (_cachedList != null && now.difference(_cacheTime) < const Duration(minutes: 5)) {
      return _cachedList!;
    }
    final builtIn = trackEngine.getTracks();
    final yaml = await yamlLoader.loadTracksFromAssets();
    final tracks = <LessonTrack>[...builtIn, ...yaml];
    final unlockable = <LessonTrack>[];
    for (final t in tracks) {
      if (await canUnlockTrack(t.id)) {
        unlockable.add(t);
      }
    }
    _cachedList = unlockable;
    _cacheTime = now;
    return unlockable;
  }
}

