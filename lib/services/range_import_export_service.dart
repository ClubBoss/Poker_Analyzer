import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RangeImportExportService {
  RangeImportExportService();

  Future<File> _fileFor(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/ranges');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/$id.json');
  }

  Future<List<String>?> readRange(String id) async {
    final file = await _fileFor(id);
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return [
          for (final e in decoded)
            if (e is String) e,
        ];
      }
    } catch (_) {}
    return null;
  }

  Future<void> writeRange(String id, List<String> range) async {
    final file = await _fileFor(id);
    await file.writeAsString(jsonEncode(range));
  }
}
