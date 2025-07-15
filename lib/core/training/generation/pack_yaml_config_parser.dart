import 'pack_generation_request.dart';
import '../../../models/training_pack.dart' show parseGameType;
import 'yaml_reader.dart';

class PackYamlConfig {
  final List<PackGenerationRequest> requests;
  final bool rangeTags;
  const PackYamlConfig({required this.requests, this.rangeTags = false});
}

class PackYamlConfigParser {
  final YamlReader reader;
  const PackYamlConfigParser({YamlReader? yamlReader})
    : reader = yamlReader ?? const YamlReader();

  PackYamlConfig parse(String yamlSource) {
    final map = reader.read(yamlSource);
    final rangeTags = map['defaultRangeTags'] == true;
    final defaultGameType = map['defaultGameType'];
    final defaultDescription = map['defaultDescription']?.toString() ?? '';
    final defaultTags = <String>[
      for (final t in (map['defaultTags'] as List? ?? const [])) t.toString(),
    ];
    final defaultCount = (map['defaultCount'] as num?)?.toInt();
    final defaultMultiplePositions = map['defaultMultiplePositions'] == true;
    final defaultRangeGroup = map['defaultRangeGroup']?.toString();
    final list = map['packs'];
    if (list is! List) return const PackYamlConfig(requests: []);
    final requests = [
      for (final item in list)
        if (item is Map && item['enabled'] != false)
          PackGenerationRequest(
            gameType: parseGameType(item['gameType'] ?? defaultGameType),
            bb: (item['bb'] as num?)?.toInt() ?? 0,
            bbList: item['bbList'] is List
                ? [for (final b in item['bbList']) (b as num).toInt()]
                : null,
            positions: [
              for (final p in (item['positions'] as List? ?? const []))
                p.toString(),
            ],
            title: item['title']?.toString() ?? '',
            description: () {
              final desc = item['description']?.toString() ?? '';
              return desc.isNotEmpty ? desc : defaultDescription;
            }(),
            tags: () {
              final local = item['tags'] as List?;
              final tags = local == null || local.isEmpty
                  ? defaultTags
                  : [for (final t in local) t.toString()];
              return List<String>.from(tags);
            }(),
            count: (item.containsKey('rangeGroup') || defaultRangeGroup != null)
                ? (item['count'] as num?)?.toInt() ?? (defaultCount ?? 25)
                : item.containsKey('count')
                ? (item['count'] as num?)?.toInt() ?? 25
                : (defaultCount ?? 25),
            rangeGroup: item['rangeGroup']?.toString() ?? defaultRangeGroup,
            multiplePositions: item.containsKey('multiplePositions')
                ? item['multiplePositions'] == true
                : defaultMultiplePositions,
          ),
    ];
    return PackYamlConfig(requests: requests, rangeTags: rangeTags);
  }
}
