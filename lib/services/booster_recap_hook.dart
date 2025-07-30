import 'package:shared_preferences/shared_preferences.dart';

import '../models/booster_backlink.dart';
import '../models/training_pack.dart';
import '../models/v2/training_pack_template.dart';
import '../models/drill_result.dart';
import 'smart_theory_recap_engine.dart';
import 'theory_boost_recap_linker.dart';
import 'theory_recap_review_tracker.dart';
import '../models/theory_recap_review_entry.dart';

/// Listens to booster and drill results and triggers theory recap when needed.
class BoosterRecapHook {
  final SmartTheoryRecapEngine engine;
  BoosterRecapHook({SmartTheoryRecapEngine? engine})
      : engine = engine ?? SmartTheoryRecapEngine.instance;

  static final BoosterRecapHook instance = BoosterRecapHook();

  static const _reviewPrefix = 'review_count_';
  final Map<String, int> _reviewCache = {};

  Future<int> _incrementReview(String id) async {
    if (id.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_reviewPrefix$id';
    final count = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, count);
    _reviewCache[id] = count;
    return count;
  }

  /// Call when a hand review screen is opened.
  Future<void> onReviewOpened({required String handId, List<String>? tags}) async {
    final count = await _incrementReview(handId);
    if (count > 1) {
      await engine.maybePrompt(tags: tags);
    }
  }

  /// Call when a drill result screen is shown.
  Future<void> onDrillResult({required int mistakes, List<String>? tags}) async {
    if (mistakes >= 2) {
      await engine.maybePrompt(tags: tags);
    }
  }

  /// Call when a booster recap screen is shown.
  Future<void> onBoosterResult({
    required TrainingSessionResult result,
    required TrainingPackTemplateV2 booster,
    BoosterBacklink? backlink,
  }) async {
    final total = result.total;
    final correct = result.correct;
    final failed = total > 0 && correct / total < 0.5;
    if (!failed) return;
    String? lessonId;
    List<String>? tags = booster.tags;
    if (backlink != null) {
      tags = backlink.matchingTags.toList();
      if (backlink.relatedLessonIds.isNotEmpty) {
        lessonId = backlink.relatedLessonIds.first;
      }
    }
    lessonId ??= tags != null && tags.isNotEmpty
        ? const TheoryBoostRecapLinker().getLinkedLesson(tags.first)
        : null;
    await engine.maybePrompt(lessonId: lessonId, tags: tags);
    await TheoryRecapReviewTracker.instance.log(
      TheoryRecapReviewEntry(
        lessonId: lessonId ?? '',
        trigger: 'boosterFailure',
        timestamp: DateTime.now(),
      ),
    );
  }
}

