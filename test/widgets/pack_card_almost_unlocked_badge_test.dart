import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/training_type.dart';
import 'package:poker_analyzer/widgets/pack_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows almost unlocked badge when halfway to requirements',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'tpl_stat_pack': '{"accuracy":0.6,"last":0}',
      'tpl_prog_pack': 5,
    });

    final tpl = TrainingPackTemplateV2(
      id: 'pack',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      requiredAccuracy: 80,
      minHands: 10,
      spotCount: 20,
    );

    await tester.pumpWidget(MaterialApp(
      home: PackCard(template: tpl, onTap: () {}),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Почти разблокировано'), findsOneWidget);
  });
}
