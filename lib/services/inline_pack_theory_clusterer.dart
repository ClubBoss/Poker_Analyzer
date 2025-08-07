import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/theory_note_entry.dart';

/// Groups spots within a training pack by tag and inserts lightweight theory
/// notes before each cluster.
class InlinePackTheoryClusterer {
  const InlinePackTheoryClusterer();

  /// Returns a new [TrainingPackModel] where spots are grouped by tag and a
  /// [TheoryNoteEntry] is inserted before each cluster.
  TrainingPackModel clusterWithTheory(TrainingPackModel input) {
    if (input.spots.isEmpty) return input;

    final clusters = <String, List<TrainingPackSpot>>{};
    final order = <String>[];

    for (final spot in input.spots) {
      final key = _clusterKey(spot);
      clusters.putIfAbsent(key, () {
        order.add(key);
        return [];
      }).add(spot);
    }

    final result = <TrainingPackSpot>[];
    var noteId = 0;
    for (final tag in order) {
      final text = 'In this section, we cover [$tag] situations...';
      final note = TheoryNoteEntry(tag: tag, text: text);
      final noteSpot = TrainingPackSpot(
        id: 'theory_note_${noteId++}',
        tags: [tag],
        note: text,
        type: 'theoryNote',
        isTheoryNote: true,
        theoryNote: note,
      );
      result.add(noteSpot);
      result.addAll(clusters[tag]!);
    }

    return TrainingPackModel(
      id: input.id,
      title: input.title,
      spots: result,
      tags: input.tags,
      metadata: input.metadata,
    );
  }

  String _clusterKey(TrainingPackSpot spot) {
    if (spot.tags.isNotEmpty) return spot.tags.first;
    final skill = spot.meta['skill'];
    if (skill is String && skill.isNotEmpty) return skill;
    return 'misc';
  }
}
