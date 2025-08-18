import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/training_pack_model.dart';

class TrainingPackLibraryExporter {
  final YamlEncoder _encoder;

  const TrainingPackLibraryExporter({YamlEncoder? encoder})
    : _encoder = encoder ?? const YamlEncoder();

  Future<List<String>> saveToDirectory(
    List<TrainingPackModel> packs,
    String path,
  ) async {
    final dir = Directory(path);
    await dir.create(recursive: true);
    final result = <String>[];
    final map = exportToMap(packs);
    for (final entry in map.entries) {
      final file = File('${dir.path}/${entry.key}');
      await file.writeAsString(entry.value);
      result.add(file.path);
    }
    return result;
  }

  Map<String, String> exportToMap(List<TrainingPackModel> packs) {
    final map = <String, String>{};
    for (final p in packs) {
      map['${p.id}.yaml'] = _encoder.convert(_packToMap(p));
    }
    return map;
  }

  Map<String, dynamic> _packToMap(TrainingPackModel pack) => {
    'id': pack.id,
    'title': pack.title,
    if (pack.tags.isNotEmpty) 'tags': pack.tags,
    if (pack.metadata.isNotEmpty) 'metadata': pack.metadata,
    'spots': [for (final s in pack.spots) s.toYaml()],
  };
}
