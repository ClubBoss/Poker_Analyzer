import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../data/icm_library.dart';

class ICMScenarioLibraryInjector {
  final Map<String, List<TrainingPackSpot>> _library;

  ICMScenarioLibraryInjector({Map<String, List<TrainingPackSpot>>? library})
      : _library = library ?? ICMLibrary.spotsByType;

  TrainingPackModel injectICMSpots(TrainingPackModel input) {
    final stageTags = <String>{
      for (final t in input.tags) t.toLowerCase(),
    };
    final stage = input.metadata['stage'];
    if (stage is String) {
      stageTags.add(stage.toLowerCase());
    } else if (stage is List) {
      stageTags.addAll(stage.map((e) => e.toString().toLowerCase()));
    }

    final additions = <TrainingPackSpot>[];
    for (final entry in _library.entries) {
      if (stageTags.contains(entry.key.toLowerCase())) {
        additions.addAll(entry.value.map(_cloneInjected));
      }
    }
    if (additions.isEmpty) return input;

    final spots = <TrainingPackSpot>[...additions, ...input.spots];
    return TrainingPackModel(
      id: input.id,
      title: input.title,
      spots: spots,
      tags: List<String>.from(input.tags),
      metadata: Map<String, dynamic>.from(input.metadata),
    );
  }

  TrainingPackSpot _cloneInjected(TrainingPackSpot s) {
    final clone = TrainingPackSpot.fromJson(s.toJson());
    if (!clone.tags.contains('icm')) {
      clone.tags.add('icm');
    }
    clone.isInjected = true;
    return clone;
  }
}
