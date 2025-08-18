import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';

void main() {
  testWidgets('mistakes filter shows only incorrect spots', (tester) async {
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 'Test',
      spots: [
        TrainingPackSpot(
          id: 's1',
          title: 'Spot 1',
          hand: HandData(),
          evalResult: EvaluationResult(
            correct: true,
            expectedAction: '-',
            userEquity: 0,
            expectedEquity: 0,
          ),
        ),
        TrainingPackSpot(
          id: 's2',
          title: 'Spot 2',
          hand: HandData(),
          evalResult: EvaluationResult(
            correct: false,
            expectedAction: '-',
            userEquity: 0,
            expectedEquity: 0,
          ),
        ),
      ],
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spot 1'), findsOneWidget);
    expect(find.text('Spot 2'), findsOneWidget);
    await tester.tap(find.text('Mistakes'));
    await tester.pumpAndSettle();
    expect(find.text('Spot 1'), findsNothing);
    expect(find.text('Spot 2'), findsOneWidget);
  });
}
