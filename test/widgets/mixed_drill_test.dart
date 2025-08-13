import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_list_screen.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mixed drill creates session with N spots', (tester) async {
    final t1 = TrainingPackTemplate(
      id: 't1',
      name: 'One',
      spots: [
        for (int i = 0; i < 5; i++)
          TrainingPackSpot(id: 's1_\$i', hand: HandData())
      ],
      createdAt: DateTime.now(),
    );
    final t2 = TrainingPackTemplate(
      id: 't2',
      name: 'Two',
      spots: [
        for (int i = 0; i < 5; i++)
          TrainingPackSpot(id: 's2_\$i', hand: HandData())
      ],
      createdAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({
      'training_pack_templates': jsonEncode([t1.toJson(), t2.toJson()]),
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
    await tester.enterText(find.byType(TextField).first, '3');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
    final state = tester.state(find.byType(TrainingSessionScreen));
    final service =
        Provider.of<TrainingSessionService>(state.context, listen: false);
    expect(service.spots.length, 3);
  });
}
