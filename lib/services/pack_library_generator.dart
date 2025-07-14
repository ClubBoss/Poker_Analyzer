import 'dart:convert';
import 'dart:io';

import '../models/v2/training_pack_template.dart';
import '../models/v2/hero_position.dart';
import 'spot_template_engine.dart';
import 'yaml_pack_importer_service.dart';

class PackLibraryGenerator {
  final SpotTemplateEngine engine;
  final List<TrainingPackTemplate> _packs = [];

  PackLibraryGenerator({SpotTemplateEngine? engine})
    : engine = engine ?? SpotTemplateEngine();

  List<TrainingPackTemplate> get packs => List.unmodifiable(_packs);

  Future<void> generateAll({
    List<HeroPosition>? heroPositions,
    List<HeroPosition>? villainPositions,
    List<List<int>>? stackRanges,
    List<String>? actionTypes,
    bool includeIcm = true,
  }) async {
    _packs.clear();
    final heroes = heroPositions ?? HeroPosition.values;
    final villains = villainPositions ?? HeroPosition.values;
    final ranges =
        stackRanges ??
        const [
          [10],
          [15],
          [20],
        ];
    final actions = actionTypes ?? const ['push', 'callPush', 'minraiseFold'];
    final modes = includeIcm ? const [false, true] : const [false];
    for (final hero in heroes) {
      for (final vill in villains) {
        if (hero != vill) {
          for (final r in ranges) {
            for (final type in actions) {
              for (final icm in modes) {
                final tpl = await engine.generate(
                  heroPosition: hero,
                  villainPosition: vill,
                  stackRange: r,
                  actionType: type,
                  withIcm: icm,
                );
                _packs.add(tpl);
              }
            }
          }
        }
      }
    }
  }

  Future<void> generateFromYaml(String path) async {
    final importer = YamlPackImporterService();
    final list = await importer.loadFromYaml(path);
    _packs.clear();
    for (final t in list) {
      final tpl = await engine.generate(
        heroPosition: t.hero,
        villainPosition: t.villain,
        stackRange: t.stacks,
        actionType: t.action,
        withIcm: t.icm,
        name: t.name,
      );
      _packs.add(tpl);
    }
  }

  Future<void> saveToJson(String path) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final p in _packs) p.toJson()]),
      flush: true,
    );
  }
}
