import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/pack_ux_metadata.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_search_index_builder.dart';
import 'dart:async';

class TrainingPackSearchService {
  final TrainingPackLibraryV2 library;
  final TrainingPackSearchIndexBuilder indexBuilder;
  final Stream<void>? _libraryChanges;
  StreamSubscription<void>? _sub;

  TrainingPackSearchService({
    TrainingPackLibraryV2? library,
    TrainingPackSearchIndexBuilder? indexBuilder,
    Stream<void>? libraryChanges,
  }) : library = library ?? TrainingPackLibraryV2.instance,
       indexBuilder = indexBuilder ?? TrainingPackSearchIndexBuilder(),
       _libraryChanges = libraryChanges;

  static final instance = TrainingPackSearchService();

  void init() {
    _sub?.cancel();
    if (_libraryChanges != null) {
      _sub = _libraryChanges.listen((_) => rebuild());
    }
    rebuild();
  }

  void dispose() {
    _sub?.cancel();
  }

  void rebuild() {
    indexBuilder.build(library.packs);
  }

  List<TrainingPackTemplateV2> query({
    TrainingPackLevel? level,
    TrainingPackTopic? topic,
    List<String>? tags,
    TrainingPackFormat? format,
    TrainingPackComplexity? complexity,
  }) {
    return indexBuilder.query(
      level: level,
      topic: topic,
      tags: tags,
      format: format,
      complexity: complexity,
    );
  }

  List<TrainingPackTopic> getAvailableTopics({TrainingPackLevel? level}) {
    final topics = <TrainingPackTopic>{};
    for (final p in library.packs) {
      final lvl = p.meta['level']?.toString();
      if (level != null && lvl != level.name) continue;
      final topic = p.meta['topic']?.toString();
      if (topic == null) continue;
      try {
        topics.add(TrainingPackTopic.values.byName(topic));
      } catch (_) {}
    }
    return topics.toList();
  }
}
