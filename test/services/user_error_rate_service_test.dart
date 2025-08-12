import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/user_error_rate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserErrorRateService.instance.reset();
  });

  test('EWMA gives more weight to recent mistakes', () async {
    final service = UserErrorRateService.instance;
    final now = DateTime.now();
    await service.recordAttempt(
      packId: 'p',
      tags: {'a'},
      isCorrect: false,
      ts: now.subtract(const Duration(days: 10)),
    );
    await service.recordAttempt(
      packId: 'p',
      tags: {'a'},
      isCorrect: true,
      ts: now.subtract(const Duration(days: 5)),
    );
    final r1 = (await service.getRates(packId: 'p', tags: {'a'}))['a']!;
    await service.recordAttempt(
      packId: 'p',
      tags: {'a'},
      isCorrect: false,
      ts: now,
    );
    final r2 = (await service.getRates(packId: 'p', tags: {'a'}))['a']!;
    expect(r2, greaterThan(r1));
  });

  test('rates isolated per pack', () async {
    final service = UserErrorRateService.instance;
    final now = DateTime.now();
    await service.recordAttempt(
      packId: 'p1',
      tags: {'a'},
      isCorrect: false,
      ts: now,
    );
    await service.recordAttempt(
      packId: 'p2',
      tags: {'a'},
      isCorrect: true,
      ts: now,
    );
    final r1 = (await service.getRates(packId: 'p1', tags: {'a'}))['a'];
    final r2 = (await service.getRates(packId: 'p2', tags: {'a'}))['a'];
    expect(r1, isNot(equals(r2)));
  });

  test('unseen tags return zero', () async {
    final service = UserErrorRateService.instance;
    final rates = await service.getRates(packId: 'p', tags: {'a', 'b'});
    expect(rates['a'], 0);
    expect(rates['b'], 0);
  });
}
