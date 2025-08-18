import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/learning_path_progress_stats.dart';
import 'package:poker_analyzer/widgets/learning_path_progress_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const template = LearningPathTemplateV2(
    id: 'p1',
    title: 'Path',
    description: '',
    stages: [
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
      LearningPathStageModel(
        id: 's3',
        title: 'Stage 3',
        description: '',
        packId: 'pack3',
        requiredAccuracy: 0,
        minHands: 5,
      ),
    ],
  );

  const stats = LearningPathProgressStats(
    totalStages: 3,
    completedStages: 1,
    completionPercent: 1 / 3,
    sections: [
      SectionStats(
        id: 'sec1',
        title: 'Intro',
        completedStages: 1,
        totalStages: 2,
      ),
      SectionStats(
        id: 'sec2',
        title: 'Advanced',
        completedStages: 0,
        totalStages: 1,
      ),
    ],
    lockedStageIds: ['s3'],
  );

  testWidgets('renders progress and sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningPathProgressWidget(template: template, stats: stats),
      ),
    );

    expect(find.text('1/3 стадий - 33%'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator).first,
    );
    expect(bar.value, closeTo(1 / 3, 0.01));
    expect(find.text('Intro'), findsOneWidget);
    await tester.tap(find.textContaining('Заблокированные стадии'));
    await tester.pump();
    expect(find.textContaining('Stage 3'), findsOneWidget);
  });
}
