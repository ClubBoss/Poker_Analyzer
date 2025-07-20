import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_cooldown_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks recent suggestions', () async {
    await PackCooldownTracker.markAsSuggested('a');
    expect(await PackCooldownTracker.isRecentlySuggested('a'), isTrue);
  });

  test('cooldown expires', () async {
    final past = DateTime.now().subtract(const Duration(hours: 50));
    SharedPreferences.setMockInitialValues({
      'pack_cooldown_timestamps': jsonEncode({'a': past.toIso8601String()}),
    });
    expect(await PackCooldownTracker.isRecentlySuggested('a'), isFalse);
  });

  test('old entries cleaned up', () async {
    final old = DateTime.now().subtract(const Duration(days: 31));
    SharedPreferences.setMockInitialValues({
      'pack_cooldown_timestamps': jsonEncode({'old': old.toIso8601String()}),
    });
    await PackCooldownTracker.markAsSuggested('new');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pack_cooldown_timestamps');
    final data = jsonDecode(raw!);
    expect(data.containsKey('old'), isFalse);
    expect(data.containsKey('new'), isTrue);
  });
}
