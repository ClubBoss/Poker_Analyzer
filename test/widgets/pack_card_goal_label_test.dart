import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/training_type.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/widgets/pack_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows humanized goal label when metadata provided', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final tpl = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      spotCount: 1,
      meta: {'goal': 'btnOpen'},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PackCard(template: tpl, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('BTN Open'), findsOneWidget);
  });

  testWidgets('hides goal label when metadata missing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tpl = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Pack2',
      trainingType: TrainingType.pushFold,
      spotCount: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PackCard(template: tpl, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('BTN Open'), findsNothing);
  });
}
