import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/suggestion_cooldown_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks recent suggestions', () async {
    await SuggestionCooldownManager.markSuggested('a');
    expect(await SuggestionCooldownManager.isUnderCooldown('a'), isTrue);
  });

  test('cooldown expires', () async {
    final past = DateTime.now().subtract(const Duration(hours: 50));
    SharedPreferences.setMockInitialValues({
      'suggestion_cooldowns': '{"a":"${past.toIso8601String()}"}',
    });
    expect(
      await SuggestionCooldownManager.isUnderCooldown(
        'a',
        cooldown: const Duration(hours: 48),
      ),
      isFalse,
    );
  });

  test('old entries cleaned up', () async {
    final old = DateTime.now().subtract(const Duration(days: 61));
    SharedPreferences.setMockInitialValues({
      'suggestion_cooldowns': '{"old":"${old.toIso8601String()}"}',
    });
    await SuggestionCooldownManager.markSuggested('new');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('suggestion_cooldowns');
    expect(raw!.contains('old'), isFalse);
    expect(raw.contains('new'), isTrue);
  });
}
