import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/result_entry.dart';

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
}
