import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/training_spot.dart';
import 'cloud_sync_service.dart';

class TrainingSpotStorageService {
  static const String _fileName = 'training_spots.json';

  const TrainingSpotStorageService({this.cloud});

  final CloudSyncService? cloud;

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
      for (final spot in spots) {
        await cloud!.uploadSpot(spot);
      }
    }
  }

  Future<void> addSpot(TrainingSpot spot) async {
    final spots = await load();
    spots.add(spot);
    await save(spots);
  }

  Future<void> updateSpot(TrainingSpot spot) async {
    final spots = await load();
    final index = spots.indexWhere((s) => s.createdAt == spot.createdAt);
    if (index != -1) {
      spots[index] = spot;
      await save(spots);
    }
  }

  Future<void> deleteSpot(TrainingSpot spot) async {
    final spots = await load();
    spots.removeWhere((s) => s.createdAt == spot.createdAt);
    await save(spots);
  }
}
