import 'package:collection/collection.dart';

import '../models/training_pack_model.dart';
import 'training_pack_library_importer.dart';

class PackLibraryDiffResult {
  final List<String> added;
  final List<String> removed;
  final List<String> changed;

  PackLibraryDiffResult({
    required this.added,
    required this.removed,
    required this.changed,
  });
}

class TrainingPackLibraryDiffer {
  final TrainingPackLibraryImporter importer;

  TrainingPackLibraryDiffer({TrainingPackLibraryImporter? importer})
      : importer = importer ?? TrainingPackLibraryImporter();

  Future<PackLibraryDiffResult> diff(String oldDir, String newDir) async {
    final oldPacks = await importer.loadFromDirectory(oldDir);
    final newPacks = await importer.loadFromDirectory(newDir);

    final oldMap = {for (final p in oldPacks) p.id: p};
    final newMap = {for (final p in newPacks) p.id: p};

    final added = <String>[];
    final removed = <String>[];
    final changed = <String>[];

    final equality = const DeepCollectionEquality();

    for (final id in oldMap.keys) {
      final oldPack = oldMap[id]!;
      final newPack = newMap[id];
      if (newPack == null) {
        removed.add(id);
        continue;
      }
      final oldData = _packToMap(oldPack);
      final newData = _packToMap(newPack);
      if (!equality.equals(oldData, newData)) {
        changed.add(id);
      }
    }

    for (final id in newMap.keys) {
      if (!oldMap.containsKey(id)) {
        added.add(id);
      }
    }

    added.sort();
    removed.sort();
    changed.sort();

    return PackLibraryDiffResult(
      added: added,
      removed: removed,
      changed: changed,
    );
  }

  Map<String, dynamic> _packToMap(TrainingPackModel pack) => {
        'id': pack.id,
        'title': pack.title,
        if (pack.tags.isNotEmpty) 'tags': List.of(pack.tags),
        if (pack.metadata.isNotEmpty) 'metadata': Map.of(pack.metadata),
        'spots': [for (final s in pack.spots) s.toYaml()],
      };
}
