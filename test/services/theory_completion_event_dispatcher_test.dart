import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_completion_event_dispatcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('dispatch triggers default listeners', () async {
    final dispatcher = TheoryCompletionEventDispatcher.instance;
    dispatcher.dispatch(TheoryCompletionEvent(lessonId: 'l1', wasSuccessful: true));

    await Future.delayed(const Duration(milliseconds: 10));
    final prefs = await SharedPreferences.getInstance();
    final cooldown = prefs.getString('theory_replay_cooldowns');
    expect(cooldown, isNotNull);

    final schedule = prefs.getString('theory_reinforcement_schedule');
    expect(schedule, isNotNull);

    final log = prefs.getStringList('user_action_log');
    expect(log, isNotEmpty);
  });
}
