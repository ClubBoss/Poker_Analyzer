import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/file_write_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('second process times out while first holds the lock', () async {
    SharedPreferences.setMockInitialValues({'theory.lock.timeoutSec': 1});

    final script = '''
import 'dart:io';
Future<void> main() async {
  final f = File('theory.write.lock');
  final raf = await f.open(mode: FileMode.write);
  await raf.lock(FileLock.exclusive);
  await Future.delayed(Duration(seconds: 2));
  await raf.unlock();
  await raf.close();
}
''';
    final dir = await Directory.systemTemp.createTemp('lock-test');
    final scriptFile = File('${dir.path}/hold_lock.dart');
    await scriptFile.writeAsString(script);

    final dart = Platform.resolvedExecutable;
    final p = await Process.start(dart, [scriptFile.path]);

    final sw = Stopwatch()..start();
    await expectLater(
      () async => await FileWriteLockService.instance.acquire(),
      throwsA(isA<TimeoutException>()),
    );
    sw.stop();
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(900));

    await p.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => p.kill());
    await dir.delete(recursive: true);
  });

  test('release is idempotent-ish (ignores unlock errors)', () async {
    SharedPreferences.setMockInitialValues({'theory.lock.timeoutSec': 1});
    final lock = await FileWriteLockService.instance.acquire();
    await FileWriteLockService.instance.release(lock);
    // releasing again should not throw
    await FileWriteLockService.instance.release(lock);
  });
}
