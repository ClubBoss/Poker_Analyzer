import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:poker_analyzer/services/recall_cooldown_service.dart';

void main() {
  test('recall cooldown blocks within window', () async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime(2024, 1, 1, 12, 0);
    DateTime fakeNow() => now;
    final prefs = await SharedPreferences.getInstance();
    final service = await RecallCooldownService.create(
      prefs: prefs,
      now: fakeNow,
    );
    expect(service.canShow('tag'), isTrue);
    await service.markShown('tag');
    expect(service.canShow('tag'), isFalse);
    now = now.add(const Duration(minutes: 11));
    expect(service.canShow('tag'), isTrue);
  });
}
