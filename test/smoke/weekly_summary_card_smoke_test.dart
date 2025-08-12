import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:poker_analyzer/widgets/weekly_summary_card.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/models/session_log.dart';

class _MockSessionLogService extends Mock implements SessionLogService {}
class _MockTagMasteryService extends Mock implements TagMasteryService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );
  });
  testWidgets('WeeklySummaryCard builds with fake services', (tester) async {
    final logs = _MockSessionLogService();
    final mastery = _MockTagMasteryService();

    when(() => logs.load()).thenAnswer((_) async {});
    when(() => logs.filter(range: any(named: 'range'))).thenReturn([
      SessionLog(
        sessionId: 's1',
        templateId: 't1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 1,
        mistakeCount: 0,
      ),
    ]);

    when(() => mastery.computeDelta(fromLastWeek: any(named: 'fromLastWeek')))
        .thenAnswer((_) async => {'tag': 0.1});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SessionLogService>.value(value: logs),
          Provider<TagMasteryService>.value(value: mastery),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WeeklySummaryCard(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(WeeklySummaryCard), findsOneWidget);
  });
}
