import 'dart:io';

import 'package:yaml/yaml.dart';

import 'training_pack_library_importer.dart';

class TrainingPackLibraryQAReport {
  final Map<String, List<String>> errors;

  TrainingPackLibraryQAReport({Map<String, List<String>>? errors})
      : errors = errors ?? {};

  bool get hasErrors => errors.values.any((e) => e.isNotEmpty);
}

class TrainingPackLibraryAutoQAService {
  final TrainingPackLibraryImporter importer;

  TrainingPackLibraryAutoQAService({TrainingPackLibraryImporter? importer})
      : importer = importer ?? TrainingPackLibraryImporter();

  Future<TrainingPackLibraryQAReport> validateDirectory(String path) async {
    final dir = Directory(path);
    final fileErrors = <String, List<String>>{};
    if (!await dir.exists()) {
      return TrainingPackLibraryQAReport(errors: fileErrors);
    }

    final files = <String, String>{};
    final fileToId = <String, String>{};

    await for (final entity in dir.list()) {
      if (entity is! File ||
          !(entity.path.endsWith('.yaml') || entity.path.endsWith('.yml'))) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      final content = await entity.readAsString();
      files[name] = content;
      try {
        final yaml = loadYaml(content);
        if (yaml is! Map) {
          _addError(fileErrors, name, 'YAML root is not a map');
          continue;
        }
        final id = yaml['id']?.toString();
        if (id == null || id.isEmpty) {
          _addError(fileErrors, name, 'Missing id');
        } else {
          fileToId[name] = id;
        }
        final title = yaml['title']?.toString();
        if (title == null || title.isEmpty) {
          _addError(fileErrors, name, 'Missing title');
        }
        final spotsYaml = yaml['spots'];
        if (spotsYaml is! List || spotsYaml.isEmpty) {
          _addError(fileErrors, name, 'Missing spots');
        } else {
          for (final s in spotsYaml) {
            if (s is! Map) {
              _addError(fileErrors, name, 'Spot entry is not a map');
              continue;
            }
            final sid = s['id']?.toString() ?? '';
            final hand = s['hand'];
            if (hand == null || hand is! Map) {
              _addError(fileErrors, name, 'Spot $sid missing hand');
            } else if (hand['heroIndex'] == null) {
              _addError(fileErrors, name, 'Spot $sid missing heroIndex');
            }
          }
        }
      } catch (e) {
        _addError(fileErrors, name, 'Invalid YAML: $e');
      }
    }

    // Duplicate id check
    final idToFiles = <String, List<String>>{};
    fileToId.forEach((file, id) {
      idToFiles.putIfAbsent(id, () => []).add(file);
    });
    for (final entry in idToFiles.entries) {
      if (entry.value.length > 1) {
        for (final f in entry.value) {
          final others = [
            for (final o in entry.value)
              if (o != f) o,
          ].join(', ');
          _addError(
            fileErrors,
            f,
            'Duplicate id "${entry.key}" also in $others',
          );
        }
      }
    }

    // Import packs for deeper validation
    final packs = importer.importFromMap(files);
    for (final e in importer.errors) {
      final idx = e.indexOf(':');
      if (idx > 0) {
        final file = e.substring(0, idx);
        final msg = e.substring(idx + 1).trim();
        _addError(fileErrors, file, msg);
      } else {
        _addError(fileErrors, 'general', e);
      }
    }

    final packMap = {for (final p in packs) p.id: p};
    fileToId.forEach((file, id) {
      final pack = packMap[id];
      if (pack == null) return;
      final errs = fileErrors.putIfAbsent(file, () => []);

      if (pack.title.trim().isEmpty) {
        errs.add('Missing title');
      }
      if (pack.spots.isEmpty) {
        errs.add('No spots');
      }

      final numSpots = pack.metadata['numSpots'];
      if (numSpots is int) {
        if (numSpots != pack.spots.length) {
          errs.add(
            'metadata.numSpots=$numSpots does not match spots.length=${pack.spots.length}',
          );
        }
      } else if (numSpots != null) {
        errs.add('metadata.numSpots is not an integer');
      }

      const validDiffs = ['easy', 'medium', 'hard'];
      final diff = pack.metadata['difficulty'];
      if (diff != null) {
        if (diff is! String || !validDiffs.contains(diff)) {
          errs.add('Invalid difficulty "$diff"');
        }
      }

      const validStreets = ['preflop', 'flop+turn', 'river'];
      final streets = pack.metadata['streets'];
      if (streets != null) {
        if (streets is! String || !validStreets.contains(streets)) {
          errs.add('Invalid streets "$streets"');
        }
      }

      final stackSpread = pack.metadata['stackSpread'];
      if (stackSpread != null) {
        if (stackSpread is Map) {
          final min = stackSpread['min'];
          final max = stackSpread['max'];
          if (min is! num || max is! num) {
            errs.add('stackSpread min/max must be numbers');
          } else if (min > max) {
            errs.add('stackSpread min > max');
          }
        } else {
          errs.add('stackSpread is not a map');
        }
      }

      for (final spot in pack.spots) {
        if (spot.hand.heroCards.isEmpty) {
          errs.add('Spot ${spot.id} missing hand');
        }
        if (spot.hand.heroIndex < 0 ||
            spot.hand.heroIndex >= spot.hand.playerCount) {
          errs.add('Spot ${spot.id} invalid heroIndex ${spot.hand.heroIndex}');
        }
      }

      if (errs.isEmpty) fileErrors.remove(file);
    });

    return TrainingPackLibraryQAReport(errors: fileErrors);
  }

  void _addError(Map<String, List<String>> map, String file, String message) {
    map.putIfAbsent(file, () => []).add(message);
  }
}
