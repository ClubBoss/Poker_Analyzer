import 'package:shared_preferences/shared_preferences.dart';

/// Provides idempotency guarantees for plan injection by remembering
/// recently injected plan signatures per user.
class PlanIdempotencyGuard {
  static const _prefix = 'planner.injected.';

  PlanIdempotencyGuard();

  /// Returns `true` if [sig] has not been injected for [userId] within
  /// the [window]. If it has, returns `false` indicating the caller should
  /// skip injection.
  Future<bool> shouldInject(
    String userId,
    String sig, {
    Duration window = const Duration(hours: 24),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$userId.$sig';
    final last = prefs.getInt(key);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last != null) {
      final delta = now - last;
      if (delta < window.inMilliseconds) return false;
    }
    return true;
  }

  /// Records that [sig] has been injected for [userId] at the current time.
  Future<void> recordInjected(String userId, String sig) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$userId.$sig';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }
}
