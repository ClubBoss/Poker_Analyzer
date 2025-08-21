import 'yaml_writer.dart';
import '../../../models/v2/training_pack_template.dart';

class DrillPackLibraryGenerator {
  final YamlWriter writer;
  const DrillPackLibraryGenerator({YamlWriter? yamlWriter})
      : writer = yamlWriter ?? const YamlWriter();

  Future<void> export(List<TrainingPackTemplate> packs, String path) async {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final p in packs) {
      final type = _packType(p);
      final item = _templateMap(p);
      map.putIfAbsent(type, () => []).add(item);
    }
    await writer.write(map, path);
  }

  String _packType(TrainingPackTemplate p) {
    if (p.tags.contains('starter')) return 'starter';
    if (p.tags.contains('themed')) return 'themed';
    if (p.tags.contains('icm')) return 'icm';
    if (p.tags.contains('mistake')) return 'mistake';
    if (p.tags.contains('review')) return 'review';
    return 'themed';
  }

  Map<String, dynamic> _templateMap(TrainingPackTemplate p) {
    final total = p.totalWeight;
    final ev = total == 0 ? 0 : p.evCovered * 100 / total;
    final icm = total == 0 ? 0 : p.icmCovered * 100 / total;
    return {
      'id': p.id,
      'title': p.name,
      'description': p.description,
      if (p.tags.isNotEmpty) 'tags': p.tags,
      'type': _packType(p),
      'gameType': p.gameType.name,
      'bb': p.heroBbStack,
      'position': p.heroPos.name,
      'ev': ev,
      'icm': icm,
      if (p.difficulty != null) 'difficulty': p.difficultyLevel,
      if (p.recommended) 'recommended': true,
      'spots': [for (final s in p.spots) s.toJson()],
    };
  }
}
