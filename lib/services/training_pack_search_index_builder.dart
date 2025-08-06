import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/pack_ux_metadata.dart';

class TrainingPackSearchIndexBuilder {
  final Map<String, List<TrainingPackTemplateV2>> byLevel = {};
  final Map<String, List<TrainingPackTemplateV2>> byTopic = {};
  final Map<String, List<TrainingPackTemplateV2>> byTag = {};
  final Map<String, List<TrainingPackTemplateV2>> byFormat = {};
  final Map<String, List<TrainingPackTemplateV2>> byComplexity = {};

  List<TrainingPackTemplateV2> _all = [];

  void build(List<TrainingPackTemplateV2> packs) {
    _all = packs;
    byLevel.clear();
    byTopic.clear();
    byTag.clear();
    byFormat.clear();
    byComplexity.clear();

    for (final p in packs) {
      final level = p.meta['level']?.toString();
      final topic = p.meta['topic']?.toString();
      final format = p.meta['format']?.toString();
      final complexity = p.meta['complexity']?.toString();

      if (level != null) {
        byLevel.putIfAbsent(level, () => <TrainingPackTemplateV2>[]).add(p);
      }
      if (topic != null) {
        byTopic.putIfAbsent(topic, () => <TrainingPackTemplateV2>[]).add(p);
      }
      if (format != null) {
        byFormat.putIfAbsent(format, () => <TrainingPackTemplateV2>[]).add(p);
      }
      if (complexity != null) {
        byComplexity
            .putIfAbsent(complexity, () => <TrainingPackTemplateV2>[])
            .add(p);
      }
      for (final tag in p.tags) {
        final key = tag.toLowerCase();
        byTag.putIfAbsent(key, () => <TrainingPackTemplateV2>[]).add(p);
      }
    }
  }

  List<TrainingPackTemplateV2> query({
    TrainingPackLevel? level,
    TrainingPackTopic? topic,
    List<String>? tags,
    TrainingPackFormat? format,
    TrainingPackComplexity? complexity,
  }) {
    Set<TrainingPackTemplateV2>? results;

    void intersect(List<TrainingPackTemplateV2>? list) {
      if (results != null && results!.isEmpty) return;
      if (list == null) {
        results = <TrainingPackTemplateV2>{};
        return;
      }
      final set = list.toSet();
      results = results == null ? set : results!.intersection(set);
    }

    if (level != null) {
      intersect(byLevel[level.name]);
    }
    if (topic != null) {
      intersect(byTopic[topic.name]);
    }
    if (format != null) {
      intersect(byFormat[format.name]);
    }
    if (complexity != null) {
      intersect(byComplexity[complexity.name]);
    }
    if (tags != null && tags.isNotEmpty) {
      for (final t in tags) {
        intersect(byTag[t.toLowerCase()]);
      }
    }

    return results?.toList() ?? List<TrainingPackTemplateV2>.from(_all);
  }
}
