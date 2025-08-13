import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/screens/training_history/average_accuracy_summary.dart';
import 'package:poker_analyzer/screens/training_history/filter_summary.dart';
import 'package:poker_analyzer/screens/training_history/streak_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FilterSummary hides when empty', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: FilterSummary(summary: '')));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('AverageAccuracySummary shows accuracy', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AverageAccuracySummary(accuracy: 75.5),
    ));
    expect(find.textContaining('75.5'), findsOneWidget);
  });

  testWidgets('StreakSummary shows values when visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StreakSummary(show: true, current: 3, best: 5),
    ));
    expect(find.text('Текущий стрик: 3 дней'), findsOneWidget);
    expect(find.text('Лучший стрик: 5 дней'), findsOneWidget);
  });
}
