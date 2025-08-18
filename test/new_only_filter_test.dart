import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/widgets/v2/training_pack_spot_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('toggle new-only filter', (tester) async {
    final oldSpot = TrainingPackSpot(id: 'a');
    final newSpot = TrainingPackSpot(id: 'b', isNew: true);
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 't',
      spots: [oldSpot, newSpot],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsNWidgets(2));
    await tester.tap(find.byTooltip('New Only'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsOneWidget);
    await tester.tap(find.byTooltip('New Only'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsNWidgets(2));
  });
}
