import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple file-based write lock to serialize learning path mutations per user.
class PathWriteLockService {
  final String rootDir;
  final Map<String, RandomAccessFile> _handles = {};

  PathWriteLockService({required this.rootDir});

  String _lockPath(String userId) => '$rootDir/$userId.lock';

  /// Attempts to acquire a lock for [userId]. Returns `true` if acquired,
  /// otherwise `false` after the timeout expires.
  Future<bool> acquire(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final timeoutSec = prefs.getInt('path.lock.timeoutSec') ?? 10;
    final deadline = DateTime.now().add(Duration(seconds: timeoutSec));
    final file = File(_lockPath(userId));
    file.parent.createSync(recursive: true);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final raf = file.openSync(mode: FileMode.writeOnlyExclusive);
        _handles[userId] = raf;
        return true;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    return false;
  }

  /// Releases the lock for [userId].
  Future<void> release(String userId) async {
    final file = File(_lockPath(userId));
    final raf = _handles.remove(userId);
    if (raf != null) await raf.close();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
