import 'package:yaml/yaml.dart';

import '../models/theory_pack_model.dart';
import '../models/learning_path_template_v2.dart';

/// Builds YAML index of theory packs with usage metadata.
class TheoryPackAutoIndexerService {
  const TheoryPackAutoIndexerService();

  /// Returns YAML string with packs grouped by usage status.
  String buildIndexYaml(
    List<TheoryPackModel> packs,
    List<LearningPathTemplateV2> paths,
  ) {
    final packMap = {for (final p in packs) p.id: p};
    final usage = <String, Set<String>>{};
    for (final path in paths) {
      for (final stage in path.stages) {
        final id = stage.theoryPackId?.trim();
        if (id != null && id.isNotEmpty) {
          usage.putIfAbsent(id, () => <String>{}).add(path.id);
        }
        for (final b in stage.boosterTheoryPackIds ?? const []) {
          final bid = b.trim();
          if (bid.isNotEmpty) {
            usage.putIfAbsent(bid, () => <String>{}).add(path.id);
          }
        }
      }
    }

    int _wordCount(String text) =>
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    int _readTime(TheoryPackModel p) {
      final words = p.sections.fold<int>(0, (s, e) => s + _wordCount(e.text));
      if (words == 0) return 1;
      return (words / 150).ceil();
    }

    final used = <Map<String, dynamic>>[];
    final unused = <Map<String, dynamic>>[];
    final missing = <Map<String, dynamic>>[];

    for (final pack in packs) {
      final pathsUsed = usage.remove(pack.id)?.toList() ?? <String>[];
      final map = <String, dynamic>{
        'id': pack.id,
        'title': pack.title,
        'readTimeMinutes': _readTime(pack),
        'usedInPaths': pathsUsed,
      };
      if (pathsUsed.isNotEmpty) {
        used.add(map);
      } else {
        unused.add(map);
      }
    }

    for (final entry in usage.entries) {
      missing.add({
        'id': entry.key,
        'isMissing': true,
        'usedInPaths': entry.value.toList(),
      });
    }

    final data = <String, dynamic>{
      if (used.isNotEmpty) 'used': used,
      if (unused.isNotEmpty) 'unused': unused,
      if (missing.isNotEmpty) 'missing': missing,
    };

    return const YamlEncoder().convert(data);
  }
}
