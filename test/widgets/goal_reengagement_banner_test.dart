import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/training_goal.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/goal_reengagement_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/pack_library_loader_service.dart';
import 'package:poker_analyzer/widgets/goal_reengagement_banner.dart';
import 'package:provider/provider.dart';

class _FakeBundle extends CachingAssetBundle {
  final Map<String, String> data;
  _FakeBundle(this.data);
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      data[key]!;
}

class _FakeReengagementService extends GoalReengagementService {
  TrainingGoal? goal;
  int dismissCount;
  _FakeReengagementService({this.goal, this.dismissCount = 0})
      : super(logs: SessionLogService(sessions: TrainingSessionService()));
  @override
  Future<TrainingGoal?> pickReengagementGoal() async =>
      dismissCount >= 3 ? null : goal;
  @override
  Future<void> markDismissed(String tag) async {
    dismissCount++;
  }
}

Future<void> _loadLibrary() async {
  final pack = TrainingPackTemplateV2(
    id: 'p1',
    name: 'Pack',
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: const ['tag1'],
    spots: const [],
    spotCount: 0,
    positions: const [],
  );
  final bundle = _FakeBundle({
    'assets/packs/v2/library_index.json': jsonEncode([pack.toJson()]),
  });
  await PackLibraryLoaderService.instance
      .loadLibrary(); // ensure static cache not null
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets',
      (message) async {
    final key = utf8.decoder.convert(message);
    final data = bundle.data[key];
    if (data != null) {
      return ByteData.view(Uint8List.fromList(utf8.encode(data)).buffer);
    }
    return null;
  });
  // force reload
  await PackLibraryLoaderService.instance.loadLibrary();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadLibrary();
  });

  testWidgets('hidden when goal null', (tester) async {
    final service = _FakeReengagementService();
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<GoalReengagementService>.value(value: service),
        ],
        child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const GoalReengagementBannerWidget())));
    await tester.pump();
    expect(find.textContaining('Продолжим цель'), findsNothing);
  });

  testWidgets('hidden when dismissed >=3', (tester) async {
    final service = _FakeReengagementService(
      goal: const TrainingGoal('Goal', tag: 'tag1'),
      dismissCount: 3,
    );
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<GoalReengagementService>.value(value: service),
        ],
        child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const GoalReengagementBannerWidget())));
    await tester.pump();
    expect(find.textContaining('Продолжим цель'), findsNothing);
  });

  testWidgets('shows banner and launches session', (tester) async {
    final service = _FakeReengagementService(
      goal: const TrainingGoal('Goal', tag: 'tag1'),
    );
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<GoalReengagementService>.value(value: service),
        ],
        child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const GoalReengagementBannerWidget())));
    await tester.pump();
    expect(find.textContaining('Продолжим цель: tag1'), findsOneWidget);
    await tester.tap(find.text('Тренировать'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);
  });

  testWidgets('dismiss hides banner', (tester) async {
    final service = _FakeReengagementService(
      goal: const TrainingGoal('Goal', tag: 'tag1'),
    );
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<GoalReengagementService>.value(value: service),
        ],
        child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const GoalReengagementBannerWidget())));
    await tester.pump();
    expect(find.text('Скрыть'), findsOneWidget);
    await tester.tap(find.text('Скрыть'));
    await tester.pump();
    expect(service.dismissCount, 1);
    expect(find.text('Скрыть'), findsNothing);
  });
}
