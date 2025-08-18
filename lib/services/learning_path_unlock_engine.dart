import '../models/v3/lesson_track.dart';
import '../models/learning_path_template_v2.dart';
import 'learning_track_engine.dart';
import 'yaml_lesson_track_loader.dart';
import 'track_mastery_service.dart';
import 'tag_mastery_service.dart';
import 'session_log_service.dart';
import 'training_session_service.dart';
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
  }) : goalEngine = goalEngine ?? LessonGoalEngine.instance,
       streakEngine = streakEngine ?? LessonStreakEngine.instance,
       metaService = metaService ?? LessonTrackMetaService.instance,
       trackEngine = trackEngine,
       yamlLoader = yamlLoader ?? YamlLessonTrackLoader.instance,
       _prereq =
           prereq ??
           const {
             'live_exploit': ['mtt_pro'],
             'leak_fixer': ['live_exploit'],
           },
       _streakReq = streakRequirements ?? const {'leak_fixer': 3},
       _goalReq = goalRequirements ?? const {},
       _masteryReq =
           masteryRequirements ??
           const {
             'live_exploit': {'mtt_pro': 0.5},
             'leak_fixer': {'live_exploit': 0.6},
           };

  LearningPathUnlockEngine._default()
    : masteryService = TrackMasteryService(
        mastery: TagMasteryService(
          logs: SessionLogService(sessions: TrainingSessionService()),
        ),
      ),
      goalEngine = LessonGoalEngine.instance,
      streakEngine = LessonStreakEngine.instance,
      metaService = LessonTrackMetaService.instance,
      trackEngine = const LearningTrackEngine(),
      yamlLoader = YamlLessonTrackLoader.instance,
      _prereq = const {
        'live_exploit': ['mtt_pro'],
        'leak_fixer': ['live_exploit'],
      },
      _streakReq = const {'leak_fixer': 3},
      _goalReq = const {},
      _masteryReq = const {
        'live_exploit': {'mtt_pro': 0.5},
        'leak_fixer': {'live_exploit': 0.6},
      };

  static final LearningPathUnlockEngine instance =
      LearningPathUnlockEngine._default();

  final Map<String, List<String>> _prereq;
  final Map<String, int> _streakReq;
  final Map<String, int> _goalReq;
  final Map<String, Map<String, double>> _masteryReq;

  /// Exposes prerequisite track map for external logic.
  Map<String, List<String>> get prereqMap => _prereq;

  /// Exposes streak requirement map.
  Map<String, int> get streakRequirementsMap => _streakReq;

  /// Exposes goal requirement map.
  Map<String, int> get goalRequirementsMap => _goalReq;

  /// Exposes mastery requirement map.
  Map<String, Map<String, double>> get masteryRequirementsMap => _masteryReq;

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
    if (_cachedList != null &&
        now.difference(_cacheTime) < const Duration(minutes: 5)) {
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

  /// Returns a short explanation for why [trackId] is locked.
  Future<String?> getUnlockReason(String trackId) async {
    if (await canUnlockTrack(trackId)) return null;

    final builtIn = trackEngine.getTracks();
    final yaml = await yamlLoader.loadTracksFromAssets();
    final all = <LessonTrack>[...builtIn, ...yaml];
    String titleFor(String id) {
      return all
          .firstWhere(
            (e) => e.id == id,
            orElse: () => LessonTrack(
              id: id,
              title: id,
              description: '',
              stepIds: const [],
            ),
          )
          .title;
    }

    final prereq = _prereq[trackId];
    if (prereq != null) {
      for (final id in prereq) {
        final m = await metaService.load(id);
        if (m?.completedAt == null) {
          return "Complete '${titleFor(id)}'";
        }
      }
    }

    final masteryReq = _masteryReq[trackId];
    if (masteryReq != null) {
      final mastery = await masteryService.computeTrackMastery();
      for (final entry in masteryReq.entries) {
        final value = mastery[entry.key] ?? 0.0;
        if (value < entry.value) {
          final pct = (entry.value * 100).round();
          return "Mastery \u2265 $pct% in '${titleFor(entry.key)}'";
        }
      }
    }

    final streakReq = _streakReq[trackId];
    if (streakReq != null) {
      final streak = await streakEngine.getCurrentStreak();
      if (streak < streakReq) {
        return 'Reach $streakReq-day streak';
      }
    }

    final goalReq = _goalReq[trackId];
    if (goalReq != null) {
      final count = await LessonGoalStreakEngine.instance.getCurrentStreak();
      if (count < goalReq) {
        return 'Complete daily goal $goalReq days in a row';
      }
    }

    return null;
  }

  /// Returns `true` if [path] has no prerequisites or all of them
  /// are contained in [completedPathIds].
  bool isPathUnlocked(
    LearningPathTemplateV2 path,
    Set<String> completedPathIds,
  ) {
    if (path.prerequisitePathIds.isEmpty) return true;
    for (final id in path.prerequisitePathIds) {
      if (!completedPathIds.contains(id)) return false;
    }
    return true;
  }
}
