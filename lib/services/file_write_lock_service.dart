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
    final timeout = Duration(
      seconds: prefs.getInt('theory.lock.timeoutSec') ?? 10,
    );
    final start = DateTime.now();

    while (true) {
      try {
        // Fails if another process/thread holds it
        final raf = _lockFile.openSync(mode: FileMode.writeOnlyExclusive);
        return raf;
      } catch (_) {
        if (DateTime.now().difference(start) > timeout) {
          throw TimeoutException('Failed to acquire theory write lock');
        }
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }
  }

  Future<void> release(RandomAccessFile raf) async {
    // No advisory lock held, just close
    await raf.close();
  }
}

