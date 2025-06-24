import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import "package:shared_preferences/shared_preferences.dart";
import "package:uuid/uuid.dart";
import "../models/result_entry.dart";

import "../models/cloud_training_session.dart";
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
  static const String _resultsPrefix = 'cloud_results_';

  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = "cloud_user_id";
    var id = prefs.getString(key);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(key, id);
    }
    return id;
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

  /// Store session results JSON for [packName].
  Future<void> saveResults(String packName, String json) async {
    final file = await _file('$_resultsPrefix$packName.json');
    await file.writeAsString(json, flush: true);
  }

  /// Retrieve previously saved session results for [packName].
  Future<String?> loadResults(String packName) async {
    final file = await _file('$_resultsPrefix$packName.json');
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }
  Future<void> uploadSessionResult(List<ResultEntry> results, {String? comment}) async {
    final userId = await _getUserId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory("${dir.path}/training_sessions/$userId");
    await subdir.create(recursive: true);
    final file = File("${subdir.path}/$timestamp.json");
    final data = {
      'results': [for (final r in results) r.toJson()],
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'date': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// Load all uploaded training sessions for the current user.
  Future<List<CloudTrainingSession>> loadTrainingSessions() async {
    final userId = await _getUserId();
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory("${dir.path}/training_sessions/$userId");
    if (!await subdir.exists()) return [];
    final files = await subdir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    final List<CloudTrainingSession> sessions = [];
    for (final entity in files) {
      final file = entity as File;
      final name = file.path.split('/').last;
      final tsStr = name.split('.').first;
      final ts = int.tryParse(tsStr);
      final date = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now();
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is List) {
          final results = <ResultEntry>[];
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              results.add(ResultEntry.fromJson(item));
            }
          }
          sessions.add(
            CloudTrainingSession(path: file.path, date: date, results: results),
          );
        } else if (data is Map<String, dynamic>) {
          final list = data['results'];
          final results = <ResultEntry>[];
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                results.add(ResultEntry.fromJson(item));
              }
            }
          }
          sessions.add(
            CloudTrainingSession(
              path: file.path,
              date: date,
              results: results,
              comment: data['comment'] as String?,
            ),
          );
        }
      } catch (_) {}
    }
    return sessions;
  }
}
