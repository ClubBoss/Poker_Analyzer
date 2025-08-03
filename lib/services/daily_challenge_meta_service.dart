
import 'daily_challenge_service.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

enum ChallengeState { locked, available, completed }

/// Provides meta information about the Daily Challenge state.
class DailyChallengeMetaService {
  DailyChallengeMetaService._();

  static final DailyChallengeMetaService instance =
      DailyChallengeMetaService._();

  factory DailyChallengeMetaService() => instance;

  static const String _shownResultKey = 'daily_challenge_shown_result_at';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Marks that today's challenge result has been viewed.
  Future<void> markResultShown() async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await prefs.setString(_shownResultKey, today.toIso8601String());
  }

  /// Returns today's [ChallengeState].
  Future<ChallengeState> getTodayState() async {
    final prefs = await PreferencesService.getInstance();
    final service = DailyChallengeService.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (service.isCompletedToday()) {
      final shownStr = prefs.getString(_shownResultKey);
      if (shownStr != null) {
        final shown = DateTime.tryParse(shownStr);
        if (shown != null && _sameDay(shown, today)) {
          return ChallengeState.locked;
        }
      }
      return ChallengeState.completed;
    }
    return ChallengeState.available;
  }
}
