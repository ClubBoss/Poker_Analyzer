import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/training_pack_model.dart';
import '../core/training/generation/yaml_writer.dart';

class AutogenLibraryPublisherService {
  final String baseDir;
  final YamlWriter _writer;

  AutogenLibraryPublisherService({
    String? baseDir,
    YamlWriter? yamlWriter,
  })  : baseDir = baseDir ?? 'assets/training_packs/generated',
        _writer = yamlWriter ?? const YamlWriter();

  Future<void> publish(List<TrainingPackModel> curatedPacks) async {
    final dir = Directory(baseDir);
    await dir.create(recursive: true);

    final indexFile = File(p.join(baseDir, 'library_autogen_index.yaml'));
    final index = await _readIndex(indexFile);
    final existingIds = index.map((e) => e['id'].toString()).toSet();

    var published = 0;
    var skipped = 0;

    for (final pack in curatedPacks) {
      if (existingIds.contains(pack.id)) {
        skipped++;
        continue;
      }
      final fileName = 'pack_${pack.id}.yaml';
      final filePath = p.join(baseDir, fileName);
      await _writer.write(_packToYaml(pack), filePath);
      index.add({
        'id': pack.id,
        'file': fileName,
        'tags': pack.tags,
        'timestamp': DateTime.now().toIso8601String(),
      });
      existingIds.add(pack.id);
      published++;
    }

    await _writer.write(index, indexFile.path);

    final logFile = File(p.join(baseDir, 'autogen_publish_log.json'));
    final logs = await _readLogs(logFile);
    logs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'publishedCount': published,
      'skippedDuplicates': skipped,
      'totalCandidates': curatedPacks.length,
    });
    await logFile.writeAsString(jsonEncode(logs));
  }

  Map<String, dynamic> _packToYaml(TrainingPackModel pack) => {
        'id': pack.id,
        'title': pack.title,
        if (pack.tags.isNotEmpty) 'tags': pack.tags,
        if (pack.metadata.isNotEmpty) 'metadata': pack.metadata,
        'spots': [for (final s in pack.spots) s.toYaml()],
      };

  Future<List<Map<String, dynamic>>> _readIndex(File file) async {
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = loadYaml(content);
      if (data is YamlList) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }

  Future<List<dynamic>> _readLogs(File file) async {
    if (await file.exists()) {
      try {
        final data = jsonDecode(await file.readAsString());
        if (data is List) return List<dynamic>.from(data);
      } catch (_) {}
    }
    return [];
  }
}
