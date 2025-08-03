import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows btn cash lesson before training', (tester) async {
    final tpl = TrainingPackTemplateV2(
      id: 'push_fold_btn_cash',
      name: 'BTN Cash',
      trainingType: TrainingType.pushFold,
      gameType: GameType.cash,
      spots: [TrainingPackSpot(id: 's1')],
      spotCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox.shrink()),
    );

    unawaited(const TrainingSessionLauncher().launch(tpl));
    await tester.pumpAndSettle();

    expect(find.text('BTN Cash Push/Fold'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });
}
