import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PackMatrixConfig {
  const PackMatrixConfig();

  Future<List<(String, List<String>)>> loadMatrix() async {
    final str = await rootBundle.loadString('assets/pack_matrix.json');
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
}
