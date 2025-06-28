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
      unawaited(cloud!.syncUp());
    }
  }

  Future<void> addSpot(TrainingSpot spot) async {
    final spots = await load();
    spots.add(spot);
    await save(spots);
  }

  Future<int?> evaluateFilterCount(Map<String, dynamic> filters) async {
    try {
      final spots = await load();
      int count = 0;
      for (final s in spots) {
        if (!_matchesFilters(s, filters)) continue;
        count++;
      }
      return count;
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
