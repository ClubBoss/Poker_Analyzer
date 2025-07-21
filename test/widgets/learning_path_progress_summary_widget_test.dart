import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/widgets/learning_path_progress_summary_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final template = LearningPathTemplateV2(
    id: 'p1',
    title: 'Path',
    description: '',
    stages: const [
      LearningPathStageModel(
        id: 's1',
        title: 'Stage 1',
        description: '',
        packId: 'pack1',
        requiredAccuracy: 0,
        minHands: 10,
      ),
      LearningPathStageModel(
        id: 's2',
        title: 'Stage 2',
        description: '',
        packId: 'pack2',
        requiredAccuracy: 0,
        minHands: 5,
      ),
    ],
  );

  testWidgets('shows progress summary', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LearningPathProgressSummaryWidget(
          template: template,
          handsPlayedByPackId: const {'pack1': 10, 'pack2': 2},
        ),
      ),
    );

    expect(find.text('1/2 стадий'), findsOneWidget);
    expect(find.text('12/15 рук'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.7, 0.01));
    expect(find.text('70%'), findsOneWidget);
  });
}
