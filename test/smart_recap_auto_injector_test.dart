import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/theory_recap_dialog.dart';
import 'package:poker_analyzer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_recap_auto_injector.dart';
import 'package:poker_analyzer/services/recap_opportunity_detector.dart';
import 'package:poker_analyzer/services/smart_theory_recap_engine.dart';
import 'package:poker_analyzer/services/theory_recap_suppression_engine.dart';
import 'package:poker_analyzer/services/smart_theory_recap_dismissal_memory.dart';
import 'package:poker_analyzer/services/tag_retention_tracker.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeDetector implements RecapOpportunityDetector {
  final bool value;
  _FakeDetector(this.value) : super(retention: FakeRetentionTracker([]));
  @override
  Future<bool> isGoodRecapMoment() async => value;
}

class FakeRetentionTracker extends TagRetentionTracker {
  FakeRetentionTracker(List<String> tags)
    : super(
        mastery: TagMasteryService(
          logs: SessionLogService(sessions: TrainingSessionService()),
        ),
      ) {
    _tags = tags;
  }

  late final List<String> _tags;

  @override
  Future<List<String>> getDecayedTags({
    double threshold = 0.75,
    DateTime? now,
  }) async => _tags;
}

class _FakeEngine extends SmartTheoryRecapEngine {
  final TheoryMiniLessonNode? lesson;
  _FakeEngine(this.lesson);
  @override
  Future<TheoryMiniLessonNode?> getNextRecap() async => lesson;
}

class _FakeSuppression extends TheoryRecapSuppressionEngine {
  final bool value;
  _FakeSuppression(this.value) : super();
  @override
  Future<bool> shouldSuppress({
    required String lessonId,
    required String trigger,
  }) async => value;
}

class _FakeDismissal extends SmartTheoryRecapDismissalMemory {
  final bool value;
  _FakeDismissal(this.value) : super._();
  @override
  Future<bool> shouldThrottle(String key) async => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );
  }

  testWidgets('injects recap when opportunity available', (tester) async {
    await pump(tester);
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final service = SmartRecapAutoInjector(
      detector: _FakeDetector(true),
      engine: _FakeEngine(lesson),
      suppression: _FakeSuppression(false),
      dismissal: _FakeDismissal(false),
    );
    await service.maybeInject();
    await tester.pump();
    expect(find.byType(TheoryRecapDialog), findsOneWidget);
  });

  testWidgets('respects cooldown between injections', (tester) async {
    await pump(tester);
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final service = SmartRecapAutoInjector(
      detector: _FakeDetector(true),
      engine: _FakeEngine(lesson),
      suppression: _FakeSuppression(false),
      dismissal: _FakeDismissal(false),
    );
    await service.maybeInject();
    await tester.pump();
    expect(find.byType(TheoryRecapDialog), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await service.maybeInject();
    await tester.pump();
    expect(find.byType(TheoryRecapDialog), findsNothing);
  });
}
