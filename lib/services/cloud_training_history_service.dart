import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/result_entry.dart';
import '../models/session_summary.dart';
import '../models/cloud_history_entry.dart';

/// Simple storage for cloud training history.
/// Each session is stored as a JSON file per user.
class CloudTrainingHistoryService {
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'cloud_history_user_id';
    var id = prefs.getString(key);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(key, id);
    }
    return id;
  }

  Future<void> saveSession(List<ResultEntry> results) async {
    final userId = await _getUserId();
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory('${dir.path}/cloud_training_history/$userId');
    await subdir.create(recursive: true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${subdir.path}/$ts.json');
    final data = {
      'date': DateTime.now().toIso8601String(),
      'entries': [
        for (final r in results)
          {
            'userAction': r.userAction,
            'expectedAction': r.expected,
            'correct': r.correct,
            'timestamp': DateTime.now().toIso8601String(),
          }
      ],
    };
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// Load all stored training sessions for the current user.
  Future<List<CloudHistoryEntry>> loadSessions() async {
    final userId = await _getUserId();
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory('${dir.path}/cloud_training_history/$userId');
    if (!await subdir.exists()) return [];
    final files = await subdir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    final List<CloudHistoryEntry> sessions = [];
    for (final entity in files) {
      final file = entity as File;
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map<String, dynamic>) {
          final dateStr = data['date'] as String?;
          final date = dateStr != null
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now();
          final entries = data['entries'];
          if (entries is List) {
            final total = entries.length;
            final correct = entries
                .whereType<Map>()
                .where((e) => e['correct'] == true)
                .length;
            sessions.add(CloudHistoryEntry(
                path: file.path,
                summary:
                    SessionSummary(date: date, total: total, correct: correct)));
          }
        }
      } catch (_) {}
    }
    return sessions;
  }

  Future<void> deleteSession(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
