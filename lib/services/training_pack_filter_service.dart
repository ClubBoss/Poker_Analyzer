import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TrainingPackFilterService {
  TrainingPackFilterService();

  Future<List<String>> filter({
    double? minEv,
    double? minIcm,
    int? minSpots,
    int? maxSpots,
    double? maxDifficulty,
    double? minRarity,
    double? minTagsMatch,
    String path = 'training_packs/library',
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, path, 'pack_stats.json'));
    if (!file.existsSync()) return [];
    List data;
    try {
      data = jsonDecode(await file.readAsString()) as List;
    } catch (_) {
      return [];
    }
    final result = <String>[];
    for (final item in data) {
      if (item is! Map) continue;
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final count = (item['count'] as num?)?.toInt() ?? 0;
      final ev = (item['ev'] as num?)?.toDouble();
      final icm = (item['icm'] as num?)?.toDouble();
      final diff = (item['difficulty'] as num?)?.toDouble();
      final rarity = (item['rarity'] as num?)?.toDouble() ?? 0;
      final match = (item['tagsMatch'] as num?)?.toDouble() ?? 0;
      if (minEv != null && (ev == null || ev < minEv)) continue;
      if (minIcm != null && (icm == null || icm < minIcm)) continue;
      if (maxDifficulty != null && (diff ?? 0) > maxDifficulty) continue;
      if (minSpots != null && count < minSpots) continue;
      if (maxSpots != null && count > maxSpots) continue;
      if (minRarity != null && rarity < minRarity) continue;
      if (minTagsMatch != null && match < minTagsMatch) continue;
      result.add(id);
    }
    return result;
  }
}
