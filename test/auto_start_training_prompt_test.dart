import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('start training prompt flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pushSpot = TrainingPackSpot(id: 'a', tags: ['push']);
    final foldSpot = TrainingPackSpot(id: 'b', tags: ['fold']);
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 't',
      spots: [pushSpot, foldSpot],
    );
    final service = TrainingSessionService();
    await tester.pumpWidget(
      ChangeNotifierProvider<TrainingSessionService>.value(
        value: service,
        child: MaterialApp(
          home: TrainingPackTemplateEditorScreen(
            template: tpl,
            templates: [tpl],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start training session now?'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });
}
