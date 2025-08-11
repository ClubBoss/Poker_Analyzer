import 'dart:io';
import 'package:path/path.dart' as p;

import '../core/training/export/training_pack_exporter_v2.dart';
import '../core/training/factory/spot_factory_level2_engine.dart';
import '../models/game_type.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackLibraryLevel2Seeder {
  final SpotFactoryLevel2Engine engine;
  final TrainingPackExporterV2 exporter;
  const PackLibraryLevel2Seeder({
    this.engine = const SpotFactoryLevel2Engine(),
    this.exporter = const TrainingPackExporterV2(),
  });

  Future<List<String>> generate({String outDir = 'assets/packs/level2'}) async {
    final configs = <_PackConfig>[
      const _PackConfig(GameType.tournament, true, true, 'CO Open 20bb'),
      const _PackConfig(GameType.tournament, false, true, 'BTN vs CO'),
      const _PackConfig(GameType.cash, true, false, 'UTG Open 100bb'),
      const _PackConfig(GameType.cash, false, true, 'BB vs SB'),
    ];

    final paths = <String>[];
    for (final cfg in configs) {
      final count = cfg.include3betPush ? 6 : 2;
      final spots = engine.generate(
        gameType: cfg.gameType,
        isHeroFirstIn: cfg.isHeroFirstIn,
        include3betPush: cfg.include3betPush,
        count: count,
      );

      final tags = <String>{'level2'};
      for (final s in spots) {
        tags.addAll(s.tags);
      }
      final positions = <String>{for (final s in spots) s.hand.position.name};

      final tpl = TrainingPackTemplateV2(
        id: _safeId(cfg.title),
        name: cfg.title,
        description: cfg.title,
        trainingType: TrainingType.pushFold,
        tags: tags.toList(),
        spots: spots,
        spotCount: spots.length,
        created: DateTime.now(),
        gameType: cfg.gameType,
        bb: cfg.gameType == GameType.cash ? 100 : 20,
        positions: positions.toList(),
        meta: {
          'schemaVersion': '2.0.0',
          'source': 'seed/level2',
          'stage': 'level2',
        },
      );

      final yaml = exporter.exportYaml(tpl);
      final fileName = cfg.title.replaceAll(' ', '_').replaceAll('/', '_');
      final path = p.join(outDir, '$fileName.yaml');
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsString('$yaml\n', flush: true);
      paths.add(path);
    }
    return paths;
  }

  String _safeId(String title) {
    final base = title.toLowerCase().replaceAll(' ', '_');
    return base.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }
}

class _PackConfig {
  final GameType gameType;
  final bool isHeroFirstIn;
  final bool include3betPush;
  final String title;
  const _PackConfig(this.gameType, this.isHeroFirstIn, this.include3betPush, this.title);
}
