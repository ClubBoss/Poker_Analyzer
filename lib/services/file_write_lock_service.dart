// lib/services/file_write_lock_service.dart
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class FileWriteLockService {
  FileWriteLockService._();
  static final FileWriteLockService instance = FileWriteLockService._();

  final File _lockFile = File('theory.write.lock');

  Future<RandomAccessFile> acquire() async {
    final prefs = await SharedPreferences.getInstance();
    final timeout = Duration(seconds: prefs.getInt('theory.lock.timeoutSec') ?? 10);

    // Open (creates if missing), then try to acquire an exclusive advisory lock.
    final raf = await _lockFile.open(mode: FileMode.write);
    try {
      await raf.lock(FileLock.exclusive).timeout(timeout);
      return raf;
    } on TimeoutException {
      await raf.close();
      throw TimeoutException('Failed to acquire theory write lock');
    } catch (_) {
      await raf.close();
      rethrow;
    }
  }

  Future<void> release(RandomAccessFile raf) async {
    try {
      await raf.unlock();
    } catch (_) {
      // ignore unlock errors (e.g., already unlocked)
    }
    await raf.close();
  }
}

