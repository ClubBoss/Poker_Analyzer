import 'booster_path_history_service.dart';

/// Checks cooldowns for theory boosters to avoid repeating them too often.
class BoosterCooldownService {
  final BoosterPathHistoryService history;
  final Duration cooldown;

  BoosterCooldownService({
    BoosterPathHistoryService? history,
    this.cooldown = const Duration(days: 3),
  }) : history = history ?? BoosterPathHistoryService.instance;

  static final BoosterCooldownService instance = BoosterCooldownService();

  /// Returns true if [lessonId] with [tag] can be shown now.
  Future<bool> isEligible(String lessonId, String tag) async {
    final next = await nextEligibleAt(lessonId, tag);
    if (next == null) return true;
    return !next.isAfter(DateTime.now());
  }

  /// Returns the next time [lessonId] with [tag] becomes eligible, or null if
  /// never shown before.
  Future<DateTime?> nextEligibleAt(String lessonId, String tag) async {
    final normTag = tag.trim().toLowerCase();
    if (normTag.isEmpty) return null;
    final logs = await history.getHistory(tag: normTag);
    if (logs.isEmpty) return null;

    DateTime? last;
    for (final e in logs) {
      if (e.lessonId == lessonId) {
        last = e.completedAt ?? e.shownAt;
        break;
      }
    }
    last ??= logs.first.completedAt ?? logs.first.shownAt;
    return last.add(cooldown);
  }
}
