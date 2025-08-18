import 'dart:io';

import 'yaml_writer.dart';
import '../../../models/v2/training_pack_template.dart';

class PackLibraryExporter {
  final YamlWriter writer;
  const PackLibraryExporter({YamlWriter? yamlWriter})
    : writer = yamlWriter ?? const YamlWriter();

  Future<List<String>> export(
    List<TrainingPackTemplate> templates,
    String targetDir,
  ) async {
    final dir = Directory(targetDir);
    await dir.create(recursive: true);
    final paths = <String>[];
    for (final t in templates) {
      final fileName = _sanitizeFileName(
        t.name.replaceAll(' ', '_').toLowerCase(),
      );
      final path = '${dir.path}/$fileName.yaml';
      await writer.write(_templateMap(t), path);
      paths.add(path);
    }
    return paths;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
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

  String _packType(TrainingPackTemplate p) {
    if (p.tags.contains('starter')) return 'starter';
    if (p.tags.contains('themed')) return 'themed';
    if (p.tags.contains('icm')) return 'icm';
    if (p.tags.contains('mistake')) return 'mistake';
    if (p.tags.contains('review')) return 'review';
    return 'themed';
  }
}
