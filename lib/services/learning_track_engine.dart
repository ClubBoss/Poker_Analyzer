import '../models/v3/lesson_track.dart';
import '../models/learning_track.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_stats_service.dart';
import 'training_path_unlock_service.dart';

class LearningTrackEngine {
  LearningTrackEngine();

  static final List<LessonTrack> _tracks = [
    LessonTrack(
      id: 'mtt_pro',
      title: 'MTT Pro Track',
      description: 'Become a tournament crusher',
      stepIds: ['lesson1'],
    ),
    LessonTrack(
      id: 'live_exploit',
      title: 'Live Exploit Track',
      description: 'Exploitative lines for live games',
      stepIds: ['lesson1'],
    ),
    LessonTrack(
      id: 'leak_fixer',
      title: 'Leak Fixer',
      description: 'Fix your weakest spots using tags',
      stepIds: ['lesson1'],
    ),
  ];

  List<LessonTrack> getTracks() => List.unmodifiable(_tracks);

  /// Returns the track with the given [id] or `null` if not found.
  LessonTrack? getTrackById(String id) {
    for (final t in _tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Builds the current learning track based on [allPacks] and [stats].
  ///
  /// Returns a [LearningTrack] containing unlocked packs in their original
  /// order and the next recommended pack to play.
  LearningTrack computeTrack({
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
  }) {
    const unlockService = TrainingPathUnlockService();
    final unlocked = unlockService.getUnlocked(allPacks, stats);

    TrainingPackTemplateV2? next;
    for (final pack in unlocked) {
      final acc = stats[pack.id]?.accuracy ?? 0.0;
      if (acc < 0.9) {
        next = pack;
        break;
      }
    }

    return LearningTrack(unlockedPacks: unlocked, nextUpPack: next);
  }
}
