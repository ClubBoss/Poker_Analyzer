import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../models/training_spot.dart';
import '../models/training_spot_filter.dart';
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

  Future<int?> evaluateFilterCount(TrainingSpotFilter filter) async {
    try {
      final spots = await load();
      int count = 0;
      for (final s in spots) {
        if (!filter.matches(s)) continue;
        count++;
      }
      return count;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> filterAllHaveEv(TrainingSpotFilter filter) async {
    try {
      final spots = await load();
      bool any = false;
      for (final s in spots) {
        if (!filter.matches(s)) continue;
        any = true;
        bool hasEv = false;
        for (final a in s.actions) {
          if (a.playerIndex == s.heroIndex && a.ev != null) {
            hasEv = true;
            break;
          }
        }
        if (!hasEv) return false;
      }
      return any;
    } catch (_) {
      return null;
    }
  }

  Future<double?> filterEvCoverage(TrainingSpotFilter filter) async {
    try {
      final spots = await load();
      int total = 0;
      int covered = 0;
      for (final s in spots) {
        if (!filter.matches(s)) continue;
        total++;
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

}
