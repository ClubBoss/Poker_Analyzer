import 'dart:convert';
import 'dart:io';

import '../models/v2/training_pack_template.dart';
import '../models/v2/hero_position.dart';
import 'spot_template_engine.dart';
import 'yaml_pack_importer_service.dart';

class PackLibraryGenerator {
  final SpotTemplateEngine engine;
  final List<TrainingPackTemplate> _packs = [];
  final Set<String> _slugs = {};

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
    _slugs.clear();
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
                _createPack(tpl, type, hero, vill, r, icm);
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
    _slugs.clear();
    for (final t in list) {
      final tpl = await engine.generate(
        heroPosition: t.hero,
        villainPosition: t.villain,
        stackRange: t.stacks,
        actionType: t.action,
        withIcm: t.icm,
        name: t.name,
      );
      _createPack(
        tpl,
        t.action,
        t.hero,
        t.villain,
        t.stacks,
        t.icm,
        tags: t.tags,
        trending: t.trending,
        recommended: t.recommended,
      );
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

  void _createPack(
    TrainingPackTemplate tpl,
    String action,
    HeroPosition hero,
    HeroPosition villain,
    List<int> stacks,
    bool icm, {
    List<String>? tags,
    bool trending = false,
    bool recommended = false,
  }) {
    tpl.slug = _uniqueSlug(_buildSlug(action, hero, villain, stacks, icm));
    if (tags != null) {
      tpl.tags = [
        for (final tag in tags)
          if (tag.trim().isNotEmpty) tag,
      ];
    }
    tpl.trending = trending;
    tpl.recommended = recommended;
    _autoTagSpots(tpl);
    _packs.add(tpl);
  }

  void _autoTagSpots(TrainingPackTemplate tpl) {
    for (final spot in tpl.spots) {
      final posTag = 'pos:${spot.hand.position.name}';
      final stack = spot.hand.stacks['${spot.hand.heroIndex}'] ?? 0.0;
      final stackTag = 'bb:${stack.round()}';
      String? action;
      final acts = spot.hand.actions[0] ?? [];
      for (final a in acts) {
        if (a.playerIndex == spot.hand.heroIndex) {
          action = a.action;
          break;
        }
      }
      final catTag = action != null ? 'cat:$action' : null;
      final set = {...spot.tags, posTag, stackTag};
      if (catTag != null) set.add(catTag);
      spot.tags = set.toList()..sort();
      final cats = [posTag, stackTag];
      if (catTag != null) cats.add(catTag);
      spot.categories = cats;
    }
  }

  String _buildSlug(
    String action,
    HeroPosition hero,
    HeroPosition villain,
    List<int> stacks,
    bool icm,
  ) {
    String a;
    switch (action) {
      case 'push':
        a = 'push';
        break;
      case 'callPush':
        a = 'call';
        break;
      case 'minraiseFold':
        a = 'minraise';
        break;
      default:
        a = action;
    }
    final avg = stacks.isEmpty
        ? 0
        : stacks.reduce((a, b) => a + b) ~/ stacks.length;
    final prefix = icm ? 'icm-' : '';
    return '$prefix$a-${hero.name}-${avg}bb-vs-${villain.name}';
  }

  String _uniqueSlug(String base) {
    var slug = base;
    var i = 1;
    while (_slugs.contains(slug)) {
      slug = '$base-${i++}';
    }
    _slugs.add(slug);
    return slug;
  }
}
