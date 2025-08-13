import 'dart:io';
import 'package:test/test.dart';
import 'package:poker_analyzer/utils/temp_cleanup.dart';

void main() {
  test('cleanupOldTempDirs removes only old directories', () async {
    final now = DateTime(2023, 1, 10);
    final oldDir = await Directory.systemTemp.createTemp('l3_report_');
    final recentDir = await Directory.systemTemp.createTemp('l3_history_');
    await oldDir.setLastModified(now.subtract(const Duration(days: 4)));
    await recentDir.setLastModified(now);

    await cleanupOldTempDirs(prefix: 'l3_report_', now: now);
    expect(await oldDir.exists(), isFalse);
    expect(await recentDir.exists(), isTrue);

    await cleanupOldTempDirs(prefix: 'l3_history_', now: now);
    expect(await recentDir.exists(), isTrue);

    await recentDir.delete(recursive: true);
  });
}
