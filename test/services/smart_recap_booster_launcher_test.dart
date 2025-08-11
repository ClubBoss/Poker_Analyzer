import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/training_pack_template_storage_service.dart';
import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/smart_recap_booster_launcher.dart';
import 'package:poker_analyzer/services/smart_recap_booster_linker.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/screens/training_session_screen.dart';

class _FakeLinker extends SmartRecapBoosterLinker {
  final List<TrainingPackTemplateV2> packs;
  _FakeLinker(this.packs) : super(storage: TrainingPackTemplateStorageService());

  @override
  Future<List<TrainingPackTemplateV2>> getBoostersForLesson(
          TheoryMiniLessonNode lesson) async =>
      packs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('launches first matching booster', (tester) async {
    final tpl = TrainingPackTemplateV2(
      id: 'b1',
      name: 'B',
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
      spots: const [TrainingPackSpot(id: 's')],
      spotCount: 1,
      created: DateTime.now(),
      positions: const [],
    );
    final service = SmartRecapBoosterLauncher(linker: _FakeLinker([tpl]));
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => TrainingSessionService(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    await service.launchBoosterForLesson(const TheoryMiniLessonNode(id: 'l', title: '', content: '', tags: ['t']));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });

  testWidgets('shows dialog when no booster found', (tester) async {
    final service = SmartRecapBoosterLauncher(linker: _FakeLinker([]));
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => TrainingSessionService(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    await service.launchBoosterForLesson(const TheoryMiniLessonNode(id: 'l', title: '', content: '', tags: ['t']));
    await tester.pumpAndSettle();
    expect(find.text('Нет тренировок по теме. Попробуйте позже'), findsOneWidget);
  });
}
