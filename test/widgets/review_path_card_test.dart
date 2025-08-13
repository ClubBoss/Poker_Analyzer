import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/services/scheduled_training_queue_service.dart';
import 'package:poker_analyzer/services/tag_insight_reminder_engine.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/services/skill_loss_detector.dart';
import 'package:poker_analyzer/widgets/review_path_card.dart';

class MockQueue extends Mock implements ScheduledTrainingQueueService {}

class MockLibrary extends Mock implements PackLibraryService {}

class MockReminder extends Mock implements TagInsightReminderEngine {}

class MockLauncher extends Mock implements TrainingSessionLauncher {}

class FakeTemplate extends Fake implements TrainingPackTemplateV2 {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeTemplate());
  });

  testWidgets('shows empty when queue empty', (tester) async {
    final queue = MockQueue();
    when(() => queue.load()).thenAnswer((_) async {});
    when(() => queue.queue).thenReturn([]);

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPathCard(
          queue: queue,
          library: MockLibrary(),
          reminder: MockReminder(),
          launcher: MockLauncher(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Recover now'), findsNothing);
  });

  testWidgets('displays card data and reacts to tap', (tester) async {
    final queue = MockQueue();
    when(() => queue.load()).thenAnswer((_) async {});
    when(() => queue.queue).thenReturn(['p1']);
    when(() => queue.pop()).thenAnswer((_) async => 'p1');

    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack',
      tags: ['icm'],
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
    );

    final library = MockLibrary();
    when(() => library.getById('p1')).thenAnswer((_) async => pack);

    final reminder = MockReminder();
    when(() => reminder.loadLosses()).thenAnswer(
      (_) async => [SkillLoss(tag: 'icm', drop: 0.6, trend: 'decline')],
    );

    final launcher = MockLauncher();
    when(() => launcher.launch(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPathCard(
          queue: queue,
          library: library,
          reminder: reminder,
          launcher: launcher,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('icm'), findsOneWidget);
    expect(find.textContaining('Urgency 60'), findsOneWidget);
    expect(find.text('Skill drop, decline'), findsOneWidget);

    await tester.tap(find.text('Recover now'));
    await tester.pump();

    verify(() => launcher.launch(pack)).called(1);
    verify(() => queue.pop()).called(1);
  });
}
