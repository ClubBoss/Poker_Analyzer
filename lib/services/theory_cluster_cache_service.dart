import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_lesson_cluster.dart';
import '../utils/theory_lesson_cluster_serializer.dart';

/// Local cache for [TheoryLessonCluster] objects.
///
/// Clusters are stored in [SharedPreferences] using their `clusterId`
/// as part of the key, allowing quick retrieval and offline access.
class TheoryClusterCacheService {
  TheoryClusterCacheService._();
  static final TheoryClusterCacheService instance =
      TheoryClusterCacheService._();

  static const _keyPrefix = 'theory_cluster_';
  final TheoryLessonClusterSerializer _serializer =
      TheoryLessonClusterSerializer();

  /// Persists [cluster] to local storage.
  Future<void> saveCluster(TheoryLessonCluster cluster) async {
    final prefs = await SharedPreferences.getInstance();
    final json = _serializer.toJson(cluster);
    final clusterId = json['clusterId'].toString();
    await prefs.setString('$_keyPrefix$clusterId', jsonEncode(json));
  }

  /// Loads a cached cluster for [clusterId].
  ///
  /// Returns `null` if no cached cluster exists or if deserialization fails.
  Future<TheoryLessonCluster?> loadCluster(String clusterId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$clusterId');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        return _serializer.fromJson(Map<String, dynamic>.from(map)).cluster;
      }
    } catch (_) {}
    return null;
  }

  /// Removes all cached clusters.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      for (final k in prefs.getKeys())
        if (k.startsWith(_keyPrefix)) k,
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Returns ids of all cached clusters.
  Future<Set<String>> getAllClusterIds() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final k in prefs.getKeys())
        if (k.startsWith(_keyPrefix)) k.substring(_keyPrefix.length),
    };
  }
}
