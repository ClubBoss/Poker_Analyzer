import '../generated/pack_library.g.dart';
import '../models/training_pack_meta.dart';
import '../core/training/engine/training_type_engine.dart';

class TrainingPackIndexService {
  TrainingPackIndexService._();
  static final instance = TrainingPackIndexService._();

  static final Map<String, TrainingPackMeta> _index = {
    'starter_pushfold_10bb': const TrainingPackMeta(
      id: 'starter_pushfold_10bb',
      title: 'Starter Push/Fold 10bb',
      skillLevel: 'beginner',
      tags: ['starter', 'pushfold'],
      trainingType: TrainingType.pushFold,
    ),
  };

  TrainingPackMeta? getMeta(String id) {
    if (!packLibrary.containsKey(id)) return null;
    return _index[id];
  }

  List<TrainingPackMeta> getAll() {
    final result = <TrainingPackMeta>[];
    for (final id in packLibrary.keys) {
      final meta = _index[id];
      if (meta != null) result.add(meta);
    }
    return result;
  }
}
