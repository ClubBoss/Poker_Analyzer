import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class PackMatrixConfig {
  PackMatrixConfig();

  Future<List<(String, List<String>)>> loadMatrix() async {
    final file = await _getFile();
    String str;
    if (file.existsSync()) {
      str = await file.readAsString();
    } else {
      str = await rootBundle.loadString('assets/pack_matrix.json');
    }
    final data = jsonDecode(str);
    if (data is! List) return [];
    final result = <(String, List<String>)>[];
    for (final item in data) {
      if (item is Map) {
        final audience = item['audience']?.toString();
        if (audience == null) continue;
        final tagsData = item['tags'];
        final tags = <String>[];
        if (tagsData is String) {
          if (tagsData.isNotEmpty) tags.add(tagsData);
        } else if (tagsData is List) {
          for (final t in tagsData) {
            tags.add(t.toString());
          }
        }
        result.add((audience, tags));
      }
    }
    return result;
  }

  Future<void> saveMatrix(List<(String, List<String>)> matrix) async {
    final file = await _getFile();
    final data = [
      for (final item in matrix) {'audience': item.$1, 'tags': item.$2},
    ];
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/pack_matrix.json');
  }
}
