import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/screens/completed_session_history_screen.dart';
import 'package:poker_analyzer/services/completed_training_pack_registry.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TrainingPackTemplateV2 buildPack(String id) {
    return TrainingPackTemplateV2(
      id: id,
      name: 'Pack $id',
      trainingType: TrainingType.quiz,
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      spotCount: 1,
    );
  }

  testWidgets('displays loaded summaries', (tester) async {
    final registry = CompletedTrainingPackRegistry();
    final pack = buildPack('p1');
    await registry.storeCompletedPack(
      pack,
      completedAt: DateTime.utc(2024, 1, 1),
      accuracy: 0.8,
    );

    await tester.pumpWidget(
      const MaterialApp(home: CompletedSessionHistoryScreen()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quiz Pack: Pack p1'), findsOneWidget);
    expect(find.textContaining('Accuracy: 80%'), findsOneWidget);
  });

  testWidgets('shows empty state when no sessions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CompletedSessionHistoryScreen()),
    );

    await tester.pumpAndSettle();

    expect(find.text('No completed sessions yet.'), findsOneWidget);
  });
}
