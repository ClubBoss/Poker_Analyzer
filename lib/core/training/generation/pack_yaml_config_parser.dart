import 'pack_generation_request.dart';
import '../../../models/game_type.dart';
import '../../../models/training_pack.dart' show parseGameType;
import 'yaml_reader.dart';

class PackYamlConfigParser {
  final YamlReader reader;
  const PackYamlConfigParser({YamlReader? yamlReader})
    : reader = yamlReader ?? const YamlReader();

  List<PackGenerationRequest> parse(String yamlSource) {
    final map = reader.read(yamlSource);
    final defaultTags = <String>[
      for (final t in (map['defaultTags'] as List? ?? const [])) t.toString(),
    ];
    final defaultCount = (map['defaultCount'] as num?)?.toInt();
    final defaultMultiplePositions = map['defaultMultiplePositions'] == true;
    final list = map['packs'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map)
          PackGenerationRequest(
            gameType: parseGameType(item['gameType']),
            bb: (item['bb'] as num?)?.toInt() ?? 0,
            bbList: item['bbList'] is List
                ? [for (final b in item['bbList']) (b as num).toInt()]
                : null,
            positions: [
              for (final p in (item['positions'] as List? ?? const []))
                p.toString(),
            ],
            title: item['title']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            tags: () {
              final local = item['tags'] as List?;
              final tags = local == null || local.isEmpty
                  ? defaultTags
                  : [for (final t in local) t.toString()];
              return List<String>.from(tags);
            }(),
            count: item.containsKey('count')
                ? (item['count'] as num?)?.toInt() ?? 25
                : (defaultCount ?? 25),
            multiplePositions: item.containsKey('multiplePositions')
                ? item['multiplePositions'] == true
                : defaultMultiplePositions,
          ),
    ];
  }
}
