import 'package:collection/collection.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'booster_snapshot_archiver.dart';

/// Generates a markdown changelog comparing the latest two archived
/// versions of a booster pack.
class BoosterPackChangelogGenerator {
  const BoosterPackChangelogGenerator();

  /// Loads the two most recent archived versions of the booster with [id]
  /// and returns a markdown changelog summarizing the differences.
  Future<String> generateChangelog(String id,
      {String dir = 'yaml_out/booster_archive'}) async {
    final history = await const BoosterSnapshotArchiver().loadHistory(id, dir: dir);
    if (history.length < 2) return 'No history for $id';
    final latest = TrainingPackTemplateV2.fromYamlString(await history.first.readAsString());
    final previous = TrainingPackTemplateV2.fromYamlString(await history[1].readAsString());
    return buildChangelog(previous, latest);
  }

  /// Builds a markdown changelog comparing [oldPack] to [newPack].
  String buildChangelog(
    TrainingPackTemplateV2 oldPack,
    TrainingPackTemplateV2 newPack,
  ) {
    final buffer = StringBuffer('# Changelog for ${newPack.id}\n');
    buffer.writeln();

    if (oldPack.spotCount != newPack.spotCount) {
      buffer.writeln('- **Spots:** ${oldPack.spotCount} → ${newPack.spotCount}');
    }
    final oldTags = {...oldPack.tags};
    final newTags = {...newPack.tags};
    final addedTags = newTags.difference(oldTags);
    final removedTags = oldTags.difference(newTags);
    if (addedTags.isNotEmpty) {
      buffer.writeln('- **New tags:** ${addedTags.join(', ')}');
    }
    if (removedTags.isNotEmpty) {
      buffer.writeln('- **Removed tags:** ${removedTags.join(', ')}');
    }

    final mapOld = {for (final s in oldPack.spots) s.id: s};
    final mapNew = {for (final s in newPack.spots) s.id: s};

    final addedSpots = <String>[];
    final removedSpots = <String>[];
    const eq = DeepCollectionEquality();

    for (final id in {...mapOld.keys, ...mapNew.keys}) {
      final a = mapOld[id];
      final b = mapNew[id];
      if (a == null) {
        addedSpots.add(id);
        continue;
      }
      if (b == null) {
        removedSpots.add(id);
        continue;
      }
      final fields = <String>[];
      if (a.hand.position != b.hand.position) fields.add('heroPosition');
      if (!eq.equals(a.tags, b.tags)) fields.add('tags');
      if ((a.explanation ?? '').trim() != (b.explanation ?? '').trim()) {
        fields.add('explanation');
      }
      if (!eq.equals(a.hand.actions, b.hand.actions)) fields.add('action');
      if ((a.heroEv ?? 0) != (b.heroEv ?? 0) ||
          (a.heroIcmEv ?? 0) != (b.heroIcmEv ?? 0)) {
        fields.add('ev');
      }
      if (fields.isNotEmpty) {
        buffer.writeln('- $id: ${fields.join(', ')}');
      }
    }

    if (addedSpots.isNotEmpty) {
      buffer.writeln('- **Added spots:** ${addedSpots.join(', ')}');
    }
    if (removedSpots.isNotEmpty) {
      buffer.writeln('- **Removed spots:** ${removedSpots.join(', ')}');
    }

    return buffer.toString().trimRight();
  }
}
