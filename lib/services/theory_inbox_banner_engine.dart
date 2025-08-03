
import '../models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'booster_suggestion_engine.dart';

/// Fetches booster lessons for inbox banner reminders.
class TheoryInboxBannerEngine {
  final BoosterSuggestionEngine booster;
  final Duration cooldown;

  TheoryInboxBannerEngine({
    BoosterSuggestionEngine? booster,
    this.cooldown = const Duration(hours: 12),
  }) : booster = booster ?? const BoosterSuggestionEngine();

  static final TheoryInboxBannerEngine instance = TheoryInboxBannerEngine();

  static const _lastKey = 'theory_inbox_banner_last';

  TheoryMiniLessonNode? _lesson;

  /// Runs recommendation check if enough time elapsed since last run.
  Future<void> run() async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr == null ? null : DateTime.tryParse(lastStr);
    if (last != null && now.difference(last) < cooldown) return;
    final lessons = await booster.getRecommendedBoosters(maxCount: 1);
    _lesson = lessons.isNotEmpty ? lessons.first : null;
    await prefs.setString(_lastKey, now.toIso8601String());
  }

  /// Returns the recommended lesson if any.
  TheoryMiniLessonNode? get lesson => _lesson;
}
