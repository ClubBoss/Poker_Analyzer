import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class FileWriteLockService {
  FileWriteLockService._();
  static final FileWriteLockService instance = FileWriteLockService._();

  final File _lockFile = File('theory.write.lock');

  Future<RandomAccessFile> acquire() async {
    final prefs = await SharedPreferences.getInstance();
    final timeoutSec = prefs.getInt('theory.lock.timeoutSec') ?? 10;
    final timeout = Duration(seconds: timeoutSec);
    final start = DateTime.now();
    while (true) {
      try {
        final raf = await _lockFile.open(mode: FileMode.write);
        await raf.lock(FileLock.exclusive);
        return raf;
      } catch (_) {
        if (DateTime.now().difference(start) > timeout) {
          throw TimeoutException('Failed to acquire theory write lock');
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> release(RandomAccessFile raf) async {
    try {
      await raf.unlock();
    } catch (_) {}
    await raf.close();
  }
}
