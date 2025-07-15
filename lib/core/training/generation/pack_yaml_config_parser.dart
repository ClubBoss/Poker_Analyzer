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

  List<String> _readTags(dynamic source) {
    if (source is String) {
      return source.isEmpty ? [] : [source];
    }
    if (source is List) {
      return [for (final t in source) t.toString()];
    }
    return [];
  }

  PackYamlConfig parse(String yamlSource) {
    final map = reader.read(yamlSource);
    final rangeTags = map['defaultRangeTags'] == true;
    final defaultGameType = map['defaultGameType'];
    final defaultTitle = map['defaultTitle']?.toString() ?? '';
    final defaultDescription = map['defaultDescription']?.toString() ?? '';
    final defaultTags = _readTags(map['defaultTags']);
    final defaultCount = (map['defaultCount'] as num?)?.toInt() ?? 25;
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
            title: () {
              final t = item['title']?.toString() ?? '';
              return t.isNotEmpty ? t : defaultTitle;
            }(),
            description: () {
              final desc = item['description']?.toString() ?? '';
              return desc.isNotEmpty ? desc : defaultDescription;
            }(),
            tags: () {
              final local = _readTags(item['tags']);
              final tags = local.isEmpty ? defaultTags : local;
              return List<String>.from(tags);
            }(),
            count: (item['count'] as num?)?.toInt() ?? defaultCount,
            rangeGroup: item['rangeGroup']?.toString() ?? defaultRangeGroup,
            multiplePositions: item.containsKey('multiplePositions')
                ? item['multiplePositions'] == true
                : defaultMultiplePositions,
          ),
    ];
    return PackYamlConfig(requests: requests, rangeTags: rangeTags);
  }
}
