import 'package:shared_preferences/shared_preferences.dart';

import 'mistake_driven_drill_pack_generator.dart';
import 'training_session_launcher.dart';
import 'recent_pack_store.dart';

/// Automatically launches a "Fix Your Mistakes" drill when fresh mistakes
/// are available.
class MistakeDrillLauncherService {
  static const _cooldownKey = 'mistake_drill_last_launch';

  final MistakeDrivenDrillPackGenerator generator;
  final TrainingSessionLauncher launcher;
  final RecentPackStore store;

  MistakeDrillLauncherService({
    required this.generator,
    TrainingSessionLauncher launcher = const TrainingSessionLauncher(),
    RecentPackStore? store,
  })  : launcher = launcher,
        store = store ?? RecentPackStore.instance;

  /// Returns `true` if enough time has passed since the last auto drill.
  Future<bool> shouldTriggerAutoDrill({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_cooldownKey);
    final current = now ?? DateTime.now();
    if (last != null) {
      final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
      if (current.difference(lastDt) < const Duration(days: 1)) {
        return false;
      }
    }
    return true;
  }

  /// Marks the auto drill as shown to enforce cooldown without launching.
  Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _cooldownKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Generates a drill from recent mistakes and launches training if possible.
  Future<void> maybeLaunch() async {
    if (!await shouldTriggerAutoDrill()) return;
    final pack = await generator.generate(limit: 5);
    if (pack == null || pack.spots.isEmpty) return;
    await store.save(pack);
    await launcher.launch(pack);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cooldownKey, DateTime.now().millisecondsSinceEpoch);
  }
}
