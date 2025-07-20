
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_suggestion_cooldown_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks recent suggestions', () async {
    await PackSuggestionCooldownService.markAsSuggested('a');
    expect(await PackSuggestionCooldownService.isRecentlySuggested('a'), isTrue);
  });

  test('cooldown expires', () async {
    final past = DateTime.now().subtract(const Duration(hours: 50));
    SharedPreferences.setMockInitialValues({
      'cooldown_suggested_a': past.toIso8601String(),
    });
    expect(await PackSuggestionCooldownService.isRecentlySuggested('a'), isFalse);
  });

  test('old entries cleaned up', () async {
    final old = DateTime.now().subtract(const Duration(days: 61));
    SharedPreferences.setMockInitialValues({
      'cooldown_suggested_old': old.toIso8601String(),
    });
    await PackSuggestionCooldownService.markAsSuggested('new');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cooldown_suggested_old'), isNull);
    expect(prefs.getString('cooldown_suggested_new'), isNotNull);
  });
}
