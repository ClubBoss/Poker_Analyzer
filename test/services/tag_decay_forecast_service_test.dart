import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/tag_decay_forecast_service.dart';
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
  Future<Map<String, double>> computeTagBoostScores({
    DateTime? now,
    int recencyDays = 3,
  }) async {
    return map;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getCriticalTags filters by threshold', () async {
    final service = TagDecayForecastService(
      retention: const _FakeRetention({'a': 90, 'b': 70}),
      logger: _FakeLogger([
        RecallSuccessEntry(tag: 'a', timestamp: DateTime.now()),
        RecallSuccessEntry(tag: 'b', timestamp: DateTime.now()),
      ]),
      tuner: const _FakeTuner({}),
    );

    final tags = await service.getCriticalTags(threshold: 0.8);
    expect(tags, ['a']);
  });
}
