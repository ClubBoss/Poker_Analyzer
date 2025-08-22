import 'package:collection/collection.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class BoosterPackDiffReport {
  final int unchangedCount;
  final int addedCount;
  final int removedCount;
  final int variationCount;
  final int uniqueHandCount;
  final int uniqueBoardCount;

  BoosterPackDiffReport({
    this.unchangedCount = 0,
    this.addedCount = 0,
    this.removedCount = 0,
    this.variationCount = 0,
    this.uniqueHandCount = 0,
    this.uniqueBoardCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'unchangedCount': unchangedCount,
    'addedCount': addedCount,
    'removedCount': removedCount,
    'variationCount': variationCount,
    'uniqueHandCount': uniqueHandCount,
    'uniqueBoardCount': uniqueBoardCount,
  };

  factory BoosterPackDiffReport.fromJson(Map<String, dynamic> j) =>
      BoosterPackDiffReport(
        unchangedCount: (j['unchangedCount'] as num?)?.toInt() ?? 0,
        addedCount: (j['addedCount'] as num?)?.toInt() ?? 0,
        removedCount: (j['removedCount'] as num?)?.toInt() ?? 0,
        variationCount: (j['variationCount'] as num?)?.toInt() ?? 0,
        uniqueHandCount: (j['uniqueHandCount'] as num?)?.toInt() ?? 0,
        uniqueBoardCount: (j['uniqueBoardCount'] as num?)?.toInt() ?? 0,
      );
}

class BoosterPackDiffReporter {
  BoosterPackDiffReporter();

  BoosterPackDiffReport compare(
    TrainingPackTemplateV2 oldPack,
    TrainingPackTemplateV2 newPack,
  ) {
    final mapOld = {for (final s in oldPack.spots) s.id: s};
    final mapNew = {for (final s in newPack.spots) s.id: s};

    var unchanged = 0;
    var added = 0;
    var removed = 0;
    var variations = 0;
    final hands = <String>{};
    final boards = <String>{};

    for (final s in newPack.spots) {
      hands.add('${s.hand.position.name}|${_normCards(s.hand.heroCards)}');
      final board = s.board.isNotEmpty ? s.board : s.hand.board;
      boards.add(board.map((c) => c.toUpperCase()).join(' '));
    }

    const eq = DeepCollectionEquality();
    for (final id in {...mapOld.keys, ...mapNew.keys}) {
      final a = mapOld[id];
      final b = mapNew[id];
      if (a == null) {
        added++;
        if (b != null && _isVariation(b)) variations++;
        continue;
      }
      if (b == null) {
        removed++;
        continue;
      }
      if (eq.equals(a.toJson(), b.toJson())) {
        unchanged++;
      } else {
        variations++;
      }
    }

    return BoosterPackDiffReport(
      unchangedCount: unchanged,
      addedCount: added,
      removedCount: removed,
      variationCount: variations,
      uniqueHandCount: hands.length,
      uniqueBoardCount: boards.length,
    );
  }

  bool _isVariation(TrainingPackSpot s) =>
      s.meta['variation'] == true || s.id.contains('_var');

  String _normCards(String cards) {
    final parts = cards
        .toUpperCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    parts.sort();
    return parts.join(' ');
  }
}
