import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/widgets/v2/training_pack_spot_preview_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('toggle missing-only filter', (tester) async {
    final spot1 = TrainingPackSpot(
      id: 'a',
      hand: HandData(),
      heroEv: 1,
      heroIcmEv: 1,
    );
    final spot2 = TrainingPackSpot(id: 'b', hand: HandData());
    final spot3 = TrainingPackSpot(id: 'c', hand: HandData(), heroEv: 1);
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 't',
      spots: [spot1, spot2, spot3],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsNWidgets(3));
    await tester.tap(find.text('Missing only'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsNWidgets(2));
    await tester.tap(find.text('Missing only'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPackSpotPreviewCard), findsNWidgets(3));
  });
}
