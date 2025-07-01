import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_ai_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_ai_analyzer/models/v2/hand_data.dart';
import 'package:poker_ai_analyzer/services/training_session_service.dart';
import 'package:poker_ai_analyzer/screens/v2/training_pack_template_list_screen.dart';
import 'package:poker_ai_analyzer/screens/training_session_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('play button opens training session', (tester) async {
    final template = TrainingPackTemplate(
      id: 't1',
      name: 'Test',
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      createdAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({
      'training_pack_templates': jsonEncode([template.toJson()]),
    });
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TrainingSessionService(),
        child: const MaterialApp(home: TrainingPackTemplateListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });
}
