import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('select duplicates', (tester) async {
    final hand = HandData(heroCards: 'Ah Kh', position: HeroPosition.sb);
    final dup1 = TrainingPackSpot(id: 'a', hand: hand);
    final dup2 = TrainingPackSpot(id: 'b', hand: hand);
    final unique = TrainingPackSpot(
      id: 'c',
      hand: HandData(heroCards: '2c 2d'),
    );
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 't',
      spots: [dup1, dup2, unique],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Duplicate').first);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
  });
}
