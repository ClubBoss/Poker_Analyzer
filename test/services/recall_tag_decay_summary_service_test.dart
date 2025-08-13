import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/recall_tag_decay_summary_service.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/recall_success_logger_service.dart';
import 'package:poker_analyzer/services/inbox_booster_tuner_service.dart';
import 'package:poker_analyzer/models/recall_success_entry.dart';

class _FakeRetention extends DecayTagRetentionTrackerService {
  final Map<String, double> scores;
  const _FakeRetention(this.scores);
  @override
  Future<double> getDecayScore(String tag, {DateTime? now}) async {
    return scores[tag] ?? 0.0;
  }
}

class _FakeLogger extends RecallSuccessLoggerService {
  final List<RecallSuccessEntry> entries;
  _FakeLogger(this.entries) : super._();
  @override
  Future<List<RecallSuccessEntry>> getSuccesses({String? tag}) async {
    if (tag == null) return entries;
    return entries.where((e) => e.tag == tag).toList();
  }
}

class _FakeTuner extends InboxBoosterTunerService {
  final Map<String, double> map;
  const _FakeTuner(this.map);
  @override
  Future<Map<String, double>> computeTagBoostScores(
      {DateTime? now, int recencyDays = 3}) async {
    return map;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getSummary aggregates decay metrics', () async {
    final service = RecallTagDecaySummaryService(
      retention: const _FakeRetention({'a': 10, 'b': 40, 'c': 70}),
      logger: _FakeLogger([
        RecallSuccessEntry(tag: 'a', timestamp: DateTime.now()),
        RecallSuccessEntry(tag: 'b', timestamp: DateTime.now()),
      ]),
      tuner: const _FakeTuner({'b': 1.0, 'c': 1.0}),
    );

    final summary = await service.getSummary();
    expect(summary.avgDecay, closeTo(40.0, 0.01));
    expect(summary.countCritical, 1);
    expect(summary.countWarning, 2);
    expect(summary.mostDecayedTags.first, 'c');
  });

  test('getSummary handles no tags', () async {
    final service = RecallTagDecaySummaryService(
      retention: const _FakeRetention({}),
      logger: _FakeLogger([]),
      tuner: const _FakeTuner({}),
    );

    final summary = await service.getSummary();
    expect(summary.avgDecay, 0.0);
    expect(summary.countCritical, 0);
    expect(summary.countWarning, 0);
    expect(summary.mostDecayedTags, isEmpty);
  });
}
