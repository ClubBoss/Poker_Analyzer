import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/smart_recall_booster_scheduler.dart';
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
  final Map<String, List<RecallSuccessEntry>> logs;
  _FakeLogger(this.logs) : super._();
  @override
  Future<List<RecallSuccessEntry>> getSuccesses({String? tag}) async {
    if (tag == null) {
      return [for (final l in logs.values) ...l];
    }
    return List<RecallSuccessEntry>.from(logs[tag] ?? []);
  }
}

class _FakeTuner extends InboxBoosterTunerService {
  final Map<String, double> scores;
  const _FakeTuner(this.scores);
  @override
  Future<Map<String, double>> computeTagBoostScores({DateTime? now, int recencyDays = 3}) async {
    return scores;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('prioritizes high decay with low success rate', () async {
    final scheduler = SmartRecallBoosterScheduler(
      retention: const _FakeRetention({'a': 70, 'b': 65, 'c': 30}),
      logger: _FakeLogger({'a': [
        RecallSuccessEntry(tag: 'a', timestamp: DateTime.now()),
      ]}),
      tuner: const _FakeTuner({'a': 1.0, 'b': 1.0, 'c': 1.0}),
    );
    final list = await scheduler.getNextBoosters();
    expect(list.length, 3);
    expect(list.first.tag, 'b');
  });

  test('limits returned items', () async {
    final scheduler = SmartRecallBoosterScheduler(
      retention: const _FakeRetention({'a': 70, 'b': 50, 'c': 45}),
      logger: _FakeLogger({}),
      tuner: const _FakeTuner({'a': 1.0, 'b': 1.0, 'c': 1.0}),
    );
    final list = await scheduler.getNextBoosters(max: 2);
    expect(list.length, 2);
  });
}
