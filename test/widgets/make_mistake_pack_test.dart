import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:poker_analyzer/services/template_storage_service.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('make mistake pack button', (tester) async {
    final spot1 = TrainingPackSpot(
      id: 'a',
      hand: HandData(),
      tags: ['Mistake'],
    );
    final spot2 = TrainingPackSpot(id: 'b', hand: HandData());
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 'Test',
      spots: [spot1, spot2],
      createdAt: DateTime.now(),
    );
    final service = TemplateStorageService();
    await tester.pumpWidget(
      Provider<TemplateStorageService>.value(
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
    await tester.tap(find.byTooltip('Make Mistake Pack'));
    await tester.pumpAndSettle();
    expect(find.text('Test - Mistakes'), findsOneWidget);
    expect(service.templates.length, 1);
  });
}
