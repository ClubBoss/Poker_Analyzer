import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/training_type.dart';
import 'package:poker_analyzer/widgets/pack_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows level badge when metadata present', (tester) async {
    SharedPreferences.setMockInitialValues({
      'tpl_stat_pack': '{"accuracy":0.0,"last":0}',
      'tpl_prog_pack': 0,
    });
    final tpl = TrainingPackTemplateV2(
      id: 'pack',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      spotCount: 20,
      meta: {'level': 'beginner'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PackCard(template: tpl, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beginner'), findsOneWidget);
  });

  testWidgets('hides level badge when metadata missing', (tester) async {
    SharedPreferences.setMockInitialValues({
      'tpl_stat_pack': '{"accuracy":0.0,"last":0}',
      'tpl_prog_pack': 0,
    });
    final tpl = TrainingPackTemplateV2(
      id: 'pack2',
      name: 'Pack2',
      trainingType: TrainingType.pushFold,
      spotCount: 10,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PackCard(template: tpl, onTap: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beginner'), findsNothing);
    expect(find.text('Intermediate'), findsNothing);
    expect(find.text('Advanced'), findsNothing);
  });
}
