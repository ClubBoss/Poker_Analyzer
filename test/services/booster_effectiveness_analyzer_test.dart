import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/booster_effectiveness_analyzer.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/models/booster_path_log_entry.dart';

class _FakeHistory extends BoosterPathHistoryService {
  final List<BoosterPathLogEntry> entries;
  _FakeHistory(this.entries);
  @override
  Future<List<BoosterPathLogEntry>> getHistory({String? tag}) async {
    if (tag == null) return entries;
    final norm = tag.trim().toLowerCase();
    return entries.where((e) => e.tag == norm).toList();
  }
}

class _FakeRetention extends DecayTagRetentionTrackerService {
  final Map<String, double> scores;
  const _FakeRetention(this.scores);
  @override
  Future<double> getDecayScore(String tag, {DateTime? now}) async {
    return scores[tag] ?? 0.0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computes average decay improvement per tag', () async {
    final now = DateTime(2024, 1, 10);
    final history = _FakeHistory([
      BoosterPathLogEntry(
        lessonId: 'b1',
        tag: 'icm',
        shownAt: now.subtract(const Duration(days: 7)),
        completedAt: now.subtract(const Duration(days: 7)),
      ),
      BoosterPathLogEntry(
        lessonId: 'b2',
        tag: 'icm',
        shownAt: now.subtract(const Duration(days: 4)),
        completedAt: now.subtract(const Duration(days: 4)),
      ),
      BoosterPathLogEntry(
        lessonId: 'b3',
        tag: 'icm',
        shownAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    const retention = _FakeRetention({'icm': 1.0});
    final analyzer = BoosterEffectivenessAnalyzer(
      history: history,
      retention: retention,
    );
    final result = await analyzer.computeEffectiveness(now: now);
    expect(result['icm'], closeTo(1.0, 0.001));
  });
}
