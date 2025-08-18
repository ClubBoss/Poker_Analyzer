import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/decay_streak_progress_bar_widget.dart';
import 'package:poker_analyzer/services/decay_streak_tracker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTracker extends DecayStreakTrackerService {
  final int streak;
  const _FakeTracker(this.streak);

  @override
  Future<int> getCurrentStreak() async => streak;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows streak progress toward next milestone', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DecayStreakProgressBarWidget(tracker: _FakeTracker(5)),
      ),
    );
    await tester.pump();
    expect(find.textContaining('5-day streak'), findsOneWidget);
    expect(find.text('5 / 7'), findsOneWidget);
  });
}
