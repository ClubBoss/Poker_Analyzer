// test/services/file_write_lock_service_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/file_write_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'second process times out while first holds the lock (cross-platform)',
    () async {
      SharedPreferences.setMockInitialValues({'theory.lock.timeoutSec': 1});

      // Write a tiny Dart script that grabs the lock for ~2s
      final dir = await Directory.systemTemp.createTemp('lock-test');
      final scriptFile = File('${dir.path}/hold_lock.dart');
      await scriptFile.writeAsString('''
import 'dart:io';
Future<void> main() async {
  final f = File('theory.write.lock');
  final raf = await f.open(mode: FileMode.write);
  await raf.lock(FileLock.exclusive);
  // Hold the lock long enough for the parent to time out
  await Future.delayed(Duration(seconds: 2));
  try { await raf.unlock(); } catch (_) {}
  await raf.close();
}
''');

      // Start child to hold the lock
      final dartExe = Platform.resolvedExecutable;
      final child = await Process.start(dartExe, [scriptFile.path]);

      // Give the child a moment to acquire the lock
      await Future.delayed(const Duration(milliseconds: 150));

      final sw = Stopwatch()..start();
      await expectLater(
        () => FileWriteLockService.instance.acquire(),
        throwsA(isA<TimeoutException>()),
      );
      sw.stop();
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(900));

      // Ensure child exits and clean up
      await child.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          child.kill();
          return -1;
        },
      );
      await dir.delete(recursive: true);
    },
  );

  test('release ignores repeated calls (idempotent-ish)', () async {
    SharedPreferences.setMockInitialValues({'theory.lock.timeoutSec': 1});
    final handle = await FileWriteLockService.instance.acquire();
    await FileWriteLockService.instance.release(handle);
    // Calling release again should not throw
    await FileWriteLockService.instance.release(handle);
  });
}
