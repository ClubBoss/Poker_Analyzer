import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_path_progress_snapshot.dart';

abstract class ProgressSnapshotStorage {
  Future<void> save(String key, String value);
  Future<String?> load(String key);
}

class PrefsProgressSnapshotStorage implements ProgressSnapshotStorage {
  @override
  Future<void> save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<String?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}

class LearningPathProgressSnapshotService {
  LearningPathProgressSnapshotService({ProgressSnapshotStorage? storage})
    : storage = storage ?? PrefsProgressSnapshotStorage();

  final ProgressSnapshotStorage storage;

  static final instance = LearningPathProgressSnapshotService();

  static const _prefix = 'lp_snapshot_';

  Future<void> save(String pathId, LearningPathProgressSnapshot snap) async {
    final key = '$_prefix$pathId';
    await storage.save(key, jsonEncode(snap.toJson()));
  }

  Future<LearningPathProgressSnapshot?> load(String pathId) async {
    final key = '$_prefix$pathId';
    final raw = await storage.load(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LearningPathProgressSnapshot.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
