import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/training/generation/pack_yaml_config_parser.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackLibraryAssemblerService {
  final PackYamlConfigParser parser;
  final TrainingTypeEngine engine;
  PackLibraryAssemblerService({
    PackYamlConfigParser? parser,
    TrainingTypeEngine? engine,
  }) : parser = parser ?? const PackYamlConfigParser(),
       engine = engine ?? TrainingTypeEngine();

  Future<void> buildJsonLibrary() async {
    final dir = await getApplicationDocumentsDirectory();
    final libDir = Directory('${dir.path}/training_packs/library');
    if (!libDir.existsSync()) return;
    final files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList();
    final list = <Map<String, dynamic>>[];
    for (final file in files) {
      try {
        final source = await file.readAsString();
        final config = parser.parse(source);
        if (config.requests.isEmpty) continue;
        final requestsJson = <Map<String, dynamic>>[];
        final templates = <TrainingPackTemplateV2>[];
        for (final r in config.requests) {
          final tpl = await engine.build(TrainingType.pushFold, r);
          templates.add(tpl);
          requestsJson.add({
            'gameType': r.gameType.name,
            'bb': r.bb,
            if (r.bbList != null) 'bbList': r.bbList,
            if (r.positions.isNotEmpty) 'positions': r.positions,
            if (r.title.isNotEmpty) 'title': r.title,
            if (r.description.isNotEmpty) 'description': r.description,
            if (r.goal.isNotEmpty) 'goal': r.goal,
            if (r.audience.isNotEmpty) 'audience': r.audience,
            if (r.tags.isNotEmpty) 'tags': r.tags,
            'count': r.count,
            if (r.rangeGroup != null) 'rangeGroup': r.rangeGroup,
            if (r.multiplePositions) 'multiplePositions': true,
            if (r.recommended) 'recommended': true,
          });
        }
        if (templates.isEmpty) continue;
        final t = templates.first;
        list.add({
          'title': t.name,
          if (t.audience != null && t.audience!.isNotEmpty)
            'audience': t.audience,
          if (t.tags.isNotEmpty) 'tags': t.tags,
          'requests': requestsJson,
          if (t.meta.isNotEmpty) 'meta': t.meta,
        });
      } catch (_) {}
    }
    final out = File('assets/packs/v2/library_index.json');
    await out.create(recursive: true);
    await out.writeAsString(jsonEncode(list), flush: true);
  }
}
