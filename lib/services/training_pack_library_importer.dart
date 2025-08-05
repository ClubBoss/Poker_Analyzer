import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';

class TrainingPackLibraryImporter {
  final List<String> errors = [];

  Future<List<TrainingPackModel>> loadFromDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    final files = <String, String>{};
    await for (final entity in dir.list()) {
      if (entity is File &&
          (entity.path.endsWith('.yaml') || entity.path.endsWith('.yml'))) {
        files[entity.uri.pathSegments.last] = await entity.readAsString();
      }
    }
    return importFromMap(files);
  }

  List<TrainingPackModel> importFromMap(Map<String, String> files) {
    errors.clear();
    final packs = <TrainingPackModel>[];
    files.forEach((name, content) {
      try {
        final yaml = loadYaml(content);
        if (yaml is! Map) {
          errors.add('$name: YAML is not a map');
          return;
        }
        final map = Map<String, dynamic>.from(yaml);
        final id = map['id']?.toString();
        final title = map['title']?.toString();
        final spotsYaml = map['spots'];
        if (id == null || id.isEmpty || title == null || title.isEmpty) {
          errors.add('$name: missing id or title');
          return;
        }
        if (spotsYaml is! List || spotsYaml.isEmpty) {
          errors.add('$name: spots missing or empty');
          return;
        }
        final spots = <TrainingPackSpot>[];
        for (final s in spotsYaml) {
          if (s is Map) {
            try {
              spots.add(
                TrainingPackSpot.fromYaml(Map<String, dynamic>.from(s)),
              );
            } catch (e) {
              errors.add('$name: invalid spot - $e');
              return;
            }
          } else {
            errors.add('$name: spot is not a map');
            return;
          }
        }
        final tags =
            (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
        packs.add(
          TrainingPackModel(id: id, title: title, spots: spots, tags: tags),
        );
      } catch (e) {
        errors.add('$name: $e');
      }
    });
    return packs;
  }
}

