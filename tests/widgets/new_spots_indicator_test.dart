import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_ai_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_ai_analyzer/models/v2/hand_data.dart';
import 'package:poker_ai_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('import marks new spots and bulk selects on tap', (tester) async {
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 'Test',
      spots: [],
      createdAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({});
    final text = [
      "PokerStars Hand #1: Hold'em No Limit (\$0.01/\$0.02 USD) - 2023/01/01 00:00:00 ET",
      "Table 'Alpha' 6-max Seat #1 is the button",
      'Seat 1: Player1 (\$1 in chips)',
      'Seat 2: Player2 (\$1 in chips)',
      '*** HOLE CARDS ***',
      'Dealt to Player1 [Ah Kh]',
      'Player1: raises 2 to 2',
      'Player2: folds',
      '*** SUMMARY ***',
      '',
      "PokerStars Hand #2: Hold'em No Limit (\$0.01/\$0.02 USD) - 2023/01/01 00:01:00 ET",
      "Table 'Beta' 6-max Seat #1 is the button",
      'Seat 1: Hero (\$1 in chips)',
      'Seat 2: Villain (\$1 in chips)',
      '*** HOLE CARDS ***',
      'Dealt to Hero [Qs Qd]',
      'Hero: raises 4 to 4',
      'Villain: folds',
      '*** SUMMARY ***',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    await tester.pumpWidget(MaterialApp(
      home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
    ));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(TrainingPackTemplateEditorScreen)) as dynamic;
    await state._importFromClipboardSpots();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.fiber_new), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.fiber_new).first);
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(2));
    for (final cb in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
      expect(cb.value, isTrue);
    }
  });
}

