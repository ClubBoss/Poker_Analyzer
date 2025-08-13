import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/training_history_entry_v2.dart';
import '../models/v2/training_pack_template_v2.dart';

class TrainingHistoryServiceV2 {
  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'app_data', 'training_history.json'));
  }

  static Future<List<TrainingHistoryEntryV2>> _load(File file) async {
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is List) {
        return [
          for (final e in data)
            if (e is Map)
              TrainingHistoryEntryV2.fromJson(Map<String, dynamic>.from(e))
        ];
      }
    } catch (_) {}
    return [];
  }

  static Future<void> logCompletion(TrainingPackTemplateV2 pack) async {
    final file = await _file();
    final list = await _load(file);
    list.insert(
      0,
      TrainingHistoryEntryV2(
        timestamp: DateTime.now(),
        tags: List<String>.from(pack.tags),
        packId: pack.id,
        type: pack.trainingType,
      ),
    );
    await file.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final e in list) e.toJson()]),
      flush: true,
    );
  }

  static Future<List<TrainingHistoryEntryV2>> getHistory(
      {int limit = 20}) async {
    final file = await _file();
    final list = await _load(file);
    return list.take(limit).toList();
  }

  static Future<void> replaceHistory(
      List<TrainingHistoryEntryV2> entries) async {
    final file = await _file();
    await file.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final e in entries) e.toJson()]),
      flush: true,
    );
  }
}
