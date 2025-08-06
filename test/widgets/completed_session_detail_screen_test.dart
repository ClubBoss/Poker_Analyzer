import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/screens/completed_session_detail_screen.dart';
import 'package:poker_analyzer/services/completed_training_pack_registry.dart';
import 'package:poker_analyzer/services/training_pack_fingerprint_generator.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
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

  testWidgets('displays session details', (tester) async {
    final registry = CompletedTrainingPackRegistry();
    final pack = buildPack('p1');
    await registry.storeCompletedPack(
      pack,
      completedAt: DateTime.utc(2024, 1, 1),
      accuracy: 0.8,
    );
    final fp = const TrainingPackFingerprintGenerator().generateFromTemplate(
      pack,
    );

    await tester.pumpWidget(
      MaterialApp(home: CompletedSessionDetailScreen(fingerprint: fp)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pack p1'), findsOneWidget);
    expect(find.textContaining('Training Type: Quiz'), findsOneWidget);
    expect(find.textContaining('Accuracy: 80%'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('shows not found when missing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CompletedSessionDetailScreen(fingerprint: 'missing'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Session not found'), findsOneWidget);
  });
}
