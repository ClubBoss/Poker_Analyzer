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
    final list = map['packs'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map)
          PackGenerationRequest(
            gameType: parseGameType(item['gameType']),
            bb: (item['bb'] as num?)?.toInt() ?? 0,
            positions: [
              for (final p in (item['positions'] as List? ?? const []))
                p.toString()
            ],
            title: item['title']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            tags: [for (final t in (item['tags'] as List? ?? const [])) t.toString()],
          )
    ];
  }
}
