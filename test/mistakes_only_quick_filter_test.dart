import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/widgets/v2/training_pack_spot_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('toggle mistakes-only quick filter', (tester) async {
    final ok = TrainingPackSpot(
      id: 'a',
      hand: HandData(),
      evalResult: EvaluationResult(
          correct: true, expectedAction: '-', userEquity: 0, expectedEquity: 0),
    );
    final err = TrainingPackSpot(
      id: 'b',
      hand: HandData(),
      evalResult: EvaluationResult(
          correct: false,
          expectedAction: '-',
          userEquity: 0,
          expectedEquity: 0),
    );
    final tpl = TrainingPackTemplate(id: 't', name: 't', spots: [ok, err]);
    await tester.pumpWidget(MaterialApp(
      home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsNWidgets(2));
    await tester.tap(find.byTooltip('Mistakes Only'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsOneWidget);
    await tester.tap(find.byTooltip('Mistakes Only'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsNWidgets(2));
  });
}
