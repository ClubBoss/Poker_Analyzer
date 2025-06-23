import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/training_spot.dart';
import '../models/saved_hand.dart';

/// Temporary stub for syncing data with the cloud.
///
/// In the future this will use Firebase for storage. Currently it writes
/// and reads JSON files in the application documents directory to emulate
/// remote uploads and downloads.
class CloudSyncService {
  static const String _spotsFile = 'cloud_spots.json';
  static const String _handsFile = 'cloud_hands.json';

  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  /// Upload a single [TrainingSpot].
  Future<void> uploadSpot(TrainingSpot spot) async {
    final file = await _file(_spotsFile);
    List<dynamic> data = [];
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is List) data = decoded;
      } catch (_) {}
    }
    data.add(spot.toJson());
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// Download all uploaded [TrainingSpot]s.
  Future<List<TrainingSpot>> downloadSpots() async {
    final file = await _file(_spotsFile);
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        return [
          for (final item in data)
            if (item is Map)
              TrainingSpot.fromJson(Map<String, dynamic>.from(item))
        ];
      }
    } catch (_) {}
    return [];
  }

  /// Upload a single [SavedHand].
  Future<void> uploadHand(SavedHand hand) async {
    final file = await _file(_handsFile);
    List<dynamic> data = [];
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is List) data = decoded;
      } catch (_) {}
    }
    data.add(hand.toJson());
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// Download all uploaded [SavedHand]s.
  Future<List<SavedHand>> downloadHands() async {
    final file = await _file(_handsFile);
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        return [
          for (final item in data)
            if (item is Map)
              SavedHand.fromJson(Map<String, dynamic>.from(item))
        ];
      }
    } catch (_) {}
    return [];
  }
}
