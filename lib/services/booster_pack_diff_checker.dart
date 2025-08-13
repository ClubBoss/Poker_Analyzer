import 'package:collection/collection.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class BoosterSpotDiff {
  final String id;
  final List<String> fields;
  final int oldIndex;
  final int newIndex;
  const BoosterSpotDiff({
    required this.id,
    required this.fields,
    required this.oldIndex,
    required this.newIndex,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fields': fields,
        'oldIndex': oldIndex,
        'newIndex': newIndex,
      };

  factory BoosterSpotDiff.fromJson(Map<String, dynamic> j) => BoosterSpotDiff(
        id: j['id'] as String? ?? '',
        fields: [for (final f in j['fields'] as List? ?? []) f.toString()],
        oldIndex: (j['oldIndex'] as num?)?.toInt() ?? 0,
        newIndex: (j['newIndex'] as num?)?.toInt() ?? 0,
      );
}

class BoosterDiffReport {
  final List<String> added;
  final List<String> removed;
  final List<BoosterSpotDiff> modified;
  const BoosterDiffReport({
    this.added = const [],
    this.removed = const [],
    this.modified = const [],
  });

  bool get breaking => modified.any(
      (d) => d.fields.contains('actions') || d.fields.contains('heroCards'));

  Map<String, dynamic> toJson() => {
        'added': added,
        'removed': removed,
        'modified': [for (final d in modified) d.toJson()],
        'breaking': breaking,
      };

  factory BoosterDiffReport.fromJson(Map<String, dynamic> j) =>
      BoosterDiffReport(
        added: [for (final a in j['added'] as List? ?? []) a.toString()],
        removed: [for (final r in j['removed'] as List? ?? []) r.toString()],
        modified: [
          for (final m in j['modified'] as List? ?? [])
            BoosterSpotDiff.fromJson(Map<String, dynamic>.from(m))
        ],
      );
}

class BoosterPackDiffChecker {
  const BoosterPackDiffChecker();

  BoosterDiffReport diff(
    TrainingPackTemplateV2 oldPack,
    TrainingPackTemplateV2 newPack,
  ) {
    final mapOld = <String, (TrainingPackSpot, int)>{};
    for (var i = 0; i < oldPack.spots.length; i++) {
      mapOld[oldPack.spots[i].id] = (oldPack.spots[i], i);
    }
    final mapNew = <String, (TrainingPackSpot, int)>{};
    for (var i = 0; i < newPack.spots.length; i++) {
      mapNew[newPack.spots[i].id] = (newPack.spots[i], i);
    }

    final added = <String>[];
    final removed = <String>[];
    final modified = <BoosterSpotDiff>[];

    const eq = DeepCollectionEquality();
    final ids = {...mapOld.keys, ...mapNew.keys};
    for (final id in ids) {
      final a = mapOld[id];
      final b = mapNew[id];
      if (a == null) {
        added.add(id);
        continue;
      }
      if (b == null) {
        removed.add(id);
        continue;
      }
      final sa = a.$1;
      final sb = b.$1;
      final fields = <String>[];
      if (sa.hand.heroCards.trim() != sb.hand.heroCards.trim()) {
        fields.add('heroCards');
      }
      if (sa.hand.position != sb.hand.position) {
        fields.add('heroPosition');
      }
      if (!eq.equals(sa.hand.actions, sb.hand.actions)) {
        fields.add('actions');
      }
      if ((sa.heroEv ?? 0) != (sb.heroEv ?? 0)) {
        fields.add('ev');
      }
      if (sa.note.trim() != sb.note.trim()) {
        fields.add('comment');
      }
      if (a.$2 != b.$2) {
        fields.add('order');
      }
      if (fields.isNotEmpty) {
        modified.add(
          BoosterSpotDiff(
            id: id,
            fields: fields,
            oldIndex: a.$2,
            newIndex: b.$2,
          ),
        );
      }
    }

    return BoosterDiffReport(
      added: added,
      removed: removed,
      modified: modified,
    );
  }
}
