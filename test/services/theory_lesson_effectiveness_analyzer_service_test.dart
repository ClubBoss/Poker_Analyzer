import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/recall_success_entry.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/recall_success_logger_service.dart';
import 'package:poker_analyzer/services/theory_lesson_effectiveness_analyzer_service.dart';

class _FakeSuccessLogger extends RecallSuccessLoggerService {
  final List<RecallSuccessEntry> entries;
  _FakeSuccessLogger(this.entries) : super._();

  @override
  Future<List<RecallSuccessEntry>> getSuccesses({String? tag}) async {
    if (tag == null) return entries;
    return entries.where((e) => e.tag == tag).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computes average gain and top lessons', () async {
    final retention = const DecayTagRetentionTrackerService();
    final reviewTime = DateTime(2024, 1, 11);
    final successTime = DateTime(2024, 1, 12);

    // initial review far in the past to create decay
    await retention.markTheoryReviewed('icm', time: DateTime(2024, 1, 1));

    final logger = _FakeSuccessLogger([
      RecallSuccessEntry(tag: 'icm', timestamp: successTime, source: 'l1'),
    ]);

    final analyzer = TheoryLessonEffectivenessAnalyzerService(
      retention: retention,
      logger: logger,
    );

    await analyzer.recordReview('icm', 'l1', time: reviewTime);

    final gain = await analyzer.getAverageTheoryGain('icm');
    expect(gain, closeTo(9.0, 0.001));

    final top = await analyzer.getTopEffectiveLessons(minSessions: 1);
    expect(top['l1'], closeTo(9.0, 0.001));

    final none = await analyzer.getTopEffectiveLessons(minSessions: 2);
    expect(none.containsKey('l1'), isFalse);
  });
}
