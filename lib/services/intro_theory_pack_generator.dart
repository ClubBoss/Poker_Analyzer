import 'dart:io';
import 'package:path/path.dart' as p;

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/game_type.dart';

class IntroTheoryPackGenerator {
  final YamlReader reader;
  const IntroTheoryPackGenerator({YamlReader? yamlReader})
    : reader = yamlReader ?? const YamlReader();

  Future<int> generate({
    String src = 'assets/packs/v2',
    String out = 'assets/packs/v2/generated',
    List<String> tags = const ['btnPush', 'limped', '3betPush'],
  }) async {
    final dir = Directory(src);
    if (!dir.existsSync()) return 0;

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));

    final Map<String, List<TrainingPackSpot>> spotMap = {
      for (final t in tags) t: <TrainingPackSpot>[],
    };

    for (final file in files) {
      try {
        final yaml = await file.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        if (tpl.meta['manualSource'] == true) continue;
        for (final s in tpl.spots) {
          if (s.type != 'theory') continue;
          for (final t in tags) {
            if (s.tags.contains(t)) {
              spotMap[t]!.add(TrainingPackSpot.fromJson(s.toJson()));
            }
          }
        }
      } catch (_) {}
    }

    await Directory(out).create(recursive: true);
    var count = 0;
    for (final entry in spotMap.entries) {
      final tag = entry.key;
      final spots = entry.value;
      if (spots.length < 2) continue;
      final tpl = TrainingPackTemplateV2(
        id: '${tag}_intro',
        name: '📘 Теория: $tag',
        trainingType: TrainingType.pushFold,
        tags: [tag],
        spots: spots,
        spotCount: spots.length,
        created: DateTime.now(),
        gameType: GameType.tournament,
        meta: {'schemaVersion': '2.0.0'},
      );
      tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
      final file = File(p.join(out, '${tag}_intro.yaml'));
      await file.writeAsString(tpl.toYamlString());
      count++;
    }
    return count;
  }
}
