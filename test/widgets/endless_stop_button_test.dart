import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_list_screen.dart';
import 'package:poker_analyzer/screens/session_result_screen.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('endless drill stop shows summary', (tester) async {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(actions: {0: [ActionEntry(0, 0, 'fold')]}),
    );
    final tpl = TrainingPackTemplate(
      id: 't1',
      name: 'One',
      spots: [spot],
      createdAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({
      'training_pack_templates': jsonEncode([tpl.toJson()]),
    });
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TrainingSessionService(),
        child: const MaterialApp(home: TrainingPackTemplateListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mixed Drill'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1');
    await tester.tap(find.text('Endless Drill'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
    await tester.tap(find.text('FOLD'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Stop Drill & show summary'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionResultScreen), findsOneWidget);
    expect(find.textContaining(' / 1'), findsOneWidget);
  });
}
