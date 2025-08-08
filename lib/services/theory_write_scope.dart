import 'file_write_lock_service.dart';

class TheoryWriteScope {
  static Future<T> run<T>(Future<T> Function() fn) async {
    final lock = await FileWriteLockService.instance.acquire();
    try {
      return await fn();
    } finally {
      await FileWriteLockService.instance.release(lock);
    }
  }
}
