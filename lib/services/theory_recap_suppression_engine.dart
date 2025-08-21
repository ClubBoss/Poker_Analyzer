import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recap_analytics_summary.dart';
import 'theory_recap_analytics_summarizer.dart';

/// Decides when recap prompts should be temporarily suppressed
/// based on recent engagement analytics.
class TheoryRecapSuppressionEngine {
  final TheoryRecapAnalyticsSummarizer summarizer;
  TheoryRecapSuppressionEngine({TheoryRecapAnalyticsSummarizer? summarizer})
      : summarizer = summarizer ?? TheoryRecapAnalyticsSummarizer();

  static final TheoryRecapSuppressionEngine instance =
      TheoryRecapSuppressionEngine();

  static const _prefsKey = 'theory_recap_suppressions';
  Map<String, DateTime>? _cache;

  Future<Map<String, DateTime>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _cache = {
            for (final e in data.entries)
              if (e.value is String &&
                  DateTime.tryParse(e.value as String) != null)
                e.key.toString(): DateTime.parse(e.value as String),
          };
          return _cache!;
        }
      } catch (_) {}
    }
    _cache = <String, DateTime>{};
    return _cache!;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _cache ?? <String, DateTime>{};
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        for (final e in map.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  Future<bool> _isSuppressed(String key) async {
    final map = await _load();
    final ts = map[key];
    if (ts == null) return false;
    if (DateTime.now().isAfter(ts)) {
      map.remove(key);
      await _save();
      return false;
    }
    return true;
  }

  Future<void> _mark(String key, Duration duration) async {
    final map = await _load();
    map[key] = DateTime.now().add(duration);
    await _save();
  }

  /// Returns true if the recap prompt for [lessonId] and [trigger]
  /// should be suppressed based on recent analytics.
  Future<bool> shouldSuppress({
    required String lessonId,
    required String trigger,
  }) async {
    if (await _isSuppressed('global') ||
        await _isSuppressed('lesson:$lessonId') ||
        await _isSuppressed('trigger:$trigger')) {
      return true;
    }

    final RecapAnalyticsSummary summary = await summarizer.summarize();
    bool suppressed = false;

    final rate = summary.acceptanceRatesByTrigger[trigger] ?? 100;
    if (rate < 20) {
      await _mark('trigger:$trigger', const Duration(hours: 48));
      suppressed = true;
    }

    if (summary.ignoredStreakCount >= 3) {
      await _mark('global', const Duration(hours: 12));
      suppressed = true;
    }

    if (summary.mostDismissedLessonIds.take(3).contains(lessonId)) {
      await _mark('lesson:$lessonId', const Duration(hours: 12));
      suppressed = true;
    }

    return suppressed;
  }

  /// Returns suppression reason if any without updating state.
  /// Possible reasons: 'globalCooldown', 'lessonCooldown', 'triggerCooldown',
  /// 'lowAcceptance', 'ignoredStreak', 'mostDismissed'.
  Future<String?> getSuppressionReason({
    required String lessonId,
    required String trigger,
  }) async {
    if (await _isSuppressed('global')) return 'globalCooldown';
    if (await _isSuppressed('lesson:$lessonId')) return 'lessonCooldown';
    if (await _isSuppressed('trigger:$trigger')) return 'triggerCooldown';

    final RecapAnalyticsSummary summary = await summarizer.summarize();

    final rate = summary.acceptanceRatesByTrigger[trigger] ?? 100;
    if (rate < 20) return 'lowAcceptance';

    if (summary.ignoredStreakCount >= 3) return 'ignoredStreak';

    if (summary.mostDismissedLessonIds.take(3).contains(lessonId)) {
      return 'mostDismissed';
    }

    return null;
  }
}
