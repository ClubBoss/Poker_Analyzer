import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:poker_analyzer/services/decay_badge_banner_controller.dart';
import 'package:poker_analyzer/services/decay_streak_badge_notifier.dart';
import 'package:poker_analyzer/services/decay_streak_tracker_service.dart';
import 'package:poker_analyzer/models/decay_streak_badge.dart';

class _FakeNotifier extends DecayStreakBadgeNotifier {
  DecayStreakBadge? badge;
  int calls = 0;
  _FakeNotifier(this.badge) : super(tracker: const DecayStreakTrackerService());

  @override
  Future<DecayStreakBadge?> checkForBadge() async {
    calls++;
    return badge;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows banner when badge earned', (tester) async {
    final notifier = _FakeNotifier(const DecayStreakBadge(3));
    final controller = DecayBadgeBannerController(notifier: notifier);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DecayBadgeBannerController>.value(value: controller),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    controller.maybeShowStreakBadgeBanner(context);
                  },
                  child: const Text('tap'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();
    expect(find.text('🔥 3-day streak!'), findsOneWidget);
    expect(notifier.calls, 1);
  });

  testWidgets('banner not repeated in same session', (tester) async {
    final notifier = _FakeNotifier(const DecayStreakBadge(3));
    final controller = DecayBadgeBannerController(notifier: notifier);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      controller.maybeShowStreakBadgeBanner(context);
                    },
                    child: const Text('a'),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.maybeShowStreakBadgeBanner(context);
                    },
                    child: const Text('b'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('a'));
    await tester.pump();
    expect(find.text('🔥 3-day streak!'), findsOneWidget);
    await tester.tap(find.text('b'));
    await tester.pump();
    expect(notifier.calls, 1);
  });

  testWidgets('no banner when badge null', (tester) async {
    final notifier = _FakeNotifier(null);
    final controller = DecayBadgeBannerController(notifier: notifier);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  controller.maybeShowStreakBadgeBanner(context);
                },
                child: const Text('tap'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('tap'));
    await tester.pump();
    expect(find.textContaining('streak'), findsNothing);
    expect(notifier.calls, 1);
  });
}
