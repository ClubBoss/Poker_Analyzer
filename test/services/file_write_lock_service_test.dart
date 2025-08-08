import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/file_write_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('second lock times out while first is held', () async {
    SharedPreferences.setMockInitialValues({'theory.lock.timeoutSec': 1});
    final lock1 = await FileWriteLockService.instance.acquire();

    final sw = Stopwatch()..start();
    await expectLater(
      () async => await FileWriteLockService.instance.acquire(),
      throwsA(isA<TimeoutException>()),
    );
    sw.stop();
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(900));

    await FileWriteLockService.instance.release(lock1);
  }, skip: Platform.isLinux);

  test('release is idempotent-ish (ignores unlock errors)', () async {
    SharedPreferences.setMockInitialValues({'theory.lock.timeoutSec': 1});
    final lock = await FileWriteLockService.instance.acquire();
    await FileWriteLockService.instance.release(lock);
    // releasing again should not throw
    await FileWriteLockService.instance.release(lock);
  });
}
