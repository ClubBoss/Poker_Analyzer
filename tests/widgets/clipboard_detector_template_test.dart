import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clipboard paste bubble appears', (tester) async {
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 'Test',
      spots: [TrainingPackSpot(id: 's', hand: HandData())],
      createdAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({});
    await Clipboard.setData(const ClipboardData(text: 'GGPoker Hand #1'));
    await tester.pumpWidget(MaterialApp(
      home: TrainingPackTemplateEditorScreen(template: tpl, templates: [tpl]),
    ));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(TrainingPackTemplateEditorScreen)) as dynamic;
    await state._checkClipboard();
    await tester.pump();
    expect(find.text('Paste Hands'), findsOneWidget);
    await Clipboard.setData(const ClipboardData(text: 'foo'));
    await state._checkClipboard();
    await tester.pump();
    expect(find.text('Paste Hands'), findsNothing);
  });
}
