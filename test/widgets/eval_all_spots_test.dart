import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/services/evaluation_executor_service.dart';
import 'package:poker_analyzer/screens/v2/training_pack_template_editor_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockEvaluationExecutorService implements EvaluationExecutorService {
  @override
  Future<EvaluationResult> evaluate(TrainingPackSpot spot) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return EvaluationResult(
      correct: true,
      expectedAction: '-',
      userEquity: 0,
      expectedEquity: 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('evaluate all spots', (tester) async {
    final tpl = TrainingPackTemplate(
      id: 't1',
      name: 'Test',
      spots: [
        TrainingPackSpot(id: 's1', hand: HandData()),
        TrainingPackSpot(id: 's2', hand: HandData()),
        TrainingPackSpot(id: 's3', hand: HandData()),
      ],
      createdAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      Provider<EvaluationExecutorService>.value(
        value: _MockEvaluationExecutorService(),
        child: MaterialApp(
          home: TrainingPackTemplateEditorScreen(
            template: tpl,
            templates: [tpl],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evaluate All'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tpl.spots.every((s) => s.evalResult != null), isTrue);
    expect(find.textContaining('3 spots'), findsOneWidget);
  });
}
