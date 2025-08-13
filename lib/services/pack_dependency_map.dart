import 'package:shared_preferences/shared_preferences.dart';

import 'learning_path_progress_service.dart';
import 'pack_library_loader_service.dart';

class PackDependencyMap {
  PackDependencyMap._();
  static final instance = PackDependencyMap._();

  static const _prefsKey = 'unlocked_pack_ids';

  final Map<String, List<String>> _deps = {};
  final Map<String, List<String>> _reverse = {};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final library = await PackLibraryLoaderService.instance.loadLibrary();
    for (final pack in library) {
      final req = pack.unlockRules?.requiredPacks ?? const [];
      if (req.isNotEmpty) {
        _deps[pack.id] = req;
        for (final r in req) {
          _reverse.putIfAbsent(r, () => []).add(pack.id);
        }
      }
    }
    _loaded = true;
  }

  Future<List<String>> getUnlockedAfter(String packId) async {
    await _load();
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList(_prefsKey) ?? <String>[];
    final dependents = _reverse[packId] ?? const [];
    final newlyUnlocked = <String>[];
    for (final dep in dependents) {
      if (unlocked.contains(dep)) continue;
      final reqs = _deps[dep] ?? const [];
      final allDone = await Future.wait(reqs
              .map((r) => LearningPathProgressService.instance.isCompleted(r)))
          .then((v) => v.every((e) => e));
      if (allDone) {
        unlocked.add(dep);
        newlyUnlocked.add(dep);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      await prefs.setStringList(_prefsKey, unlocked);
    }
    return newlyUnlocked;
  }

  Future<void> recalc() async {
    await _load();
    final prefs = await SharedPreferences.getInstance();
    final unlocked = <String>[];
    for (final entry in _deps.entries) {
      final reqs = entry.value;
      final allDone = await Future.wait(reqs
              .map((r) => LearningPathProgressService.instance.isCompleted(r)))
          .then((v) => v.every((e) => e));
      if (allDone) unlocked.add(entry.key);
    }
    await prefs.setStringList(_prefsKey, unlocked);
  }

  Future<List<String>> getUnlockedPackIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? <String>[];
  }
}
