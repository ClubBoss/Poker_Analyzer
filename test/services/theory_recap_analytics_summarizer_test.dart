import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/theory_recap_trigger_logger.dart';
import 'package:poker_analyzer/services/theory_recap_analytics_summarizer.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('summarizes recap logs', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);

    await TheoryRecapTriggerLogger.logPrompt('l1', 'weakness', 'accepted');
    await TheoryRecapTriggerLogger.logPrompt('l2', 'weakness', 'dismissed');
    await TheoryRecapTriggerLogger.logPrompt('l3', 'weakness', 'dismissed');

    final summarizer = TheoryRecapAnalyticsSummarizer();
    final summary = await summarizer.summarize(limit: 10);

    expect(summary.ignoredStreakCount, 2);
    expect(summary.acceptanceRatesByTrigger['weakness'], closeTo(33.3, 0.1));
    expect(summary.mostDismissedLessonIds.length, 2);
    expect(summary.mostDismissedLessonIds, contains('l2'));
    expect(summary.mostDismissedLessonIds, contains('l3'));

    await dir.delete(recursive: true);
  });
}
