import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../models/training_spot.dart';
import 'cloud_sync_service.dart';

class TrainingSpotStorageService extends ChangeNotifier {
  static const String _fileName = 'training_spots.json';

  TrainingSpotStorageService({this.cloud});

  final CloudSyncService? cloud;

  final Map<String, dynamic> activeFilters = {};

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<TrainingSpot>> load() async {
    final file = await _getFile();
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        return [
          for (final e in data)
            if (e is Map<String, dynamic>)
              TrainingSpot.fromJson(Map<String, dynamic>.from(e))
        ];
      }
    } catch (_) {}
    return [];
  }

  Future<void> save(List<TrainingSpot> spots) async {
    final file = await _getFile();
    await file.writeAsString(
      jsonEncode([for (final s in spots) s.toJson()]),
      flush: true,
    );
    if (cloud != null) {
      final data = {
        'spots': [for (final s in spots) s.toJson()],
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await cloud!.queueMutation('training_spots', 'main', data);
      unawaited(cloud!.syncUp());
    }
  }

  Future<void> addSpot(TrainingSpot spot) async {
    final spots = await load();
    spots.add(spot);
    await save(spots);
  }

  Future<List<TrainingSpot>> _filteredSpots(
      Map<String, dynamic> filters) async {
    final spots = await load();
    return [
      for (final s in spots)
        if (_matchesFilters(s, filters)) s,
    ];
  }

  Future<int?> evaluateFilterCount(Map<String, dynamic> filters) async {
    try {
      final spots = await _filteredSpots(filters);
      return spots.length;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> filterAllHaveEv(Map<String, dynamic> filters) async {
    try {
      final spots = await _filteredSpots(filters);
      if (spots.isEmpty) return false;
      for (final s in spots) {
        bool hasEv = false;
        for (final a in s.actions) {
          if (a.playerIndex == s.heroIndex && a.ev != null) {
            hasEv = true;
            break;
          }
        }
        if (!hasEv) return false;
      }
      return true;
    } catch (_) {
      return null;
    }
  }

  Future<double?> filterEvCoverage(Map<String, dynamic> filters) async {
    try {
      final spots = await _filteredSpots(filters);
      final total = spots.length;
      int covered = 0;
      for (final s in spots) {
        for (final a in s.actions) {
          if (a.playerIndex == s.heroIndex && a.action == 'push') {
            if (a.ev != null) covered++;
            break;
          }
        }
      }
      if (total == 0) return null;
      return covered * 100 / total;
    } catch (_) {
      return null;
    }
  }

  bool _matchesFilters(TrainingSpot spot, Map<String, dynamic> f) {
    final tags = f['tags'];
    if (tags is List && tags.isNotEmpty) {
      if (!tags.every((t) => spot.tags.contains(t))) return false;
    }
    final pos = f['positions'];
    if (pos is List && pos.isNotEmpty) {
      final hero =
          spot.positions.isNotEmpty ? spot.positions[spot.heroIndex] : '';
      if (!pos.contains(hero)) return false;
    }
    final minDiff = f['minDifficulty'];
    if (minDiff is int && spot.difficulty < minDiff) return false;
    final maxDiff = f['maxDifficulty'];
    if (maxDiff is int && spot.difficulty > maxDiff) return false;
    return true;
  }
}
