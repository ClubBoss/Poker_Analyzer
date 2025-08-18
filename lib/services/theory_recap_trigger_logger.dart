import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/theory_recap_prompt_event.dart';

class TheoryRecapTriggerLogger {
  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'app_data', 'recap_prompt_log.json'));
  }

  static Future<List<TheoryRecapPromptEvent>> _load(File file) async {
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is List) {
        return [
          for (final e in data)
            if (e is Map)
              TheoryRecapPromptEvent.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
    return [];
  }

  static Future<void> logPrompt(
    String lessonId,
    String trigger,
    String outcome,
  ) async {
    final file = await _file();
    final list = await _load(file);
    list.insert(
      0,
      TheoryRecapPromptEvent(
        lessonId: lessonId,
        trigger: trigger,
        timestamp: DateTime.now(),
        outcome: outcome,
      ),
    );
    while (list.length > 200) {
      list.removeLast();
    }
    await file.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final e in list) e.toJson()]),
      flush: true,
    );
  }

  static Future<List<TheoryRecapPromptEvent>> getRecentEvents({
    int limit = 50,
  }) async {
    final file = await _file();
    final list = await _load(file);
    return list.take(limit).toList();
  }
}
