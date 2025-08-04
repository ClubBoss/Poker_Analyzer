import 'package:shared_preferences/shared_preferences.dart';

/// Persists fingerprints of completed training sessions.
///
/// This allows the app to track which training packs were already completed
/// and avoid presenting duplicates in the future.
class TrainingSessionFingerprintRecorder {
  TrainingSessionFingerprintRecorder._();

  /// Singleton instance.
  static final TrainingSessionFingerprintRecorder instance =
      TrainingSessionFingerprintRecorder._();

  static const _key = 'completed_training_pack_fingerprints';

  /// Stores [fingerprint] in persistent storage.
  Future<void> recordCompletion(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (!list.contains(fingerprint)) {
      list.add(fingerprint);
      await prefs.setStringList(_key, list);
    }
  }

  /// Returns whether [fingerprint] was already recorded as completed.
  Future<bool> isCompleted(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.contains(fingerprint);
  }

  /// Returns all stored fingerprints.
  Future<List<String>> getAllFingerprints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  /// Clears all stored fingerprints. Useful for tests.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
