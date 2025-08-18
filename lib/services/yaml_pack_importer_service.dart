import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/v2/hero_position.dart';

class YamlPackTemplate {
  final String name;
  final HeroPosition hero;
  final HeroPosition villain;
  final List<int> stacks;
  final String action;
  final bool icm;
  final List<String> tags;
  final bool trending;
  final bool recommended;
  YamlPackTemplate({
    required this.name,
    required this.hero,
    required this.villain,
    required this.stacks,
    required this.action,
    required this.icm,
    List<String>? tags,
    this.trending = false,
    this.recommended = false,
  }) : tags = tags ?? const [];
}

class YamlPackImporterService {
  Future<List<YamlPackTemplate>> loadFromYaml(String path) async {
    final file = File(path);
    if (!file.existsSync()) return [];
    final doc = loadYaml(await file.readAsString());
    if (doc is! YamlList) return [];
    final list = <YamlPackTemplate>[];
    for (final item in doc) {
      if (item is! YamlMap) continue;
      final stacks = <int>[
        for (final v in (item['stacks'] as YamlList? ?? const []))
          (v as num).toInt(),
      ];
      final tags = <String>[
        for (final v in (item['tags'] as YamlList? ?? const [])) v.toString(),
      ];
      final trending = item['trending'] == true;
      final recommended = item['recommended'] == true;
      list.add(
        YamlPackTemplate(
          name: item['name'].toString(),
          hero: parseHeroPosition(item['hero'].toString()),
          villain: parseHeroPosition(item['villain'].toString()),
          stacks: stacks,
          action: item['action'].toString(),
          icm: item['icm'] == true,
          tags: tags,
          trending: trending,
          recommended: recommended,
        ),
      );
    }
    return list;
  }
}
