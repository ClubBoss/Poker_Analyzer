import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/recall_success_entry.dart';
import 'package:poker_analyzer/services/recall_boost_interaction_logger.dart';
import 'package:poker_analyzer/services/recall_success_logger_service.dart';
import 'package:poker_analyzer/services/theory_recall_efficiency_evaluator_service.dart';

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

  test('computes efficiency scores per tag', () async {
    final viewLogger = RecallBoostInteractionLogger.instance;
    viewLogger.resetForTest();
    await viewLogger.logView('tag1', 'node1', 1500);
    await viewLogger.logView('tag1', 'node2', 800);
    await viewLogger.logView('tag2', 'node3', 2000);

    final service = TheoryRecallEfficiencyEvaluatorService(
      viewLogger: viewLogger,
      successLogger: _FakeSuccessLogger([
        RecallSuccessEntry(tag: 'tag1', timestamp: DateTime.now()),
      ]),
    );

    final scores = await service.getEfficiencyScoresByTag();
    expect(scores['tag1'], closeTo(1.0, 0.0001));
    expect(scores['tag2'], 0.0);
  });
}

