import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class TrainingPackRatingEngine {
  const TrainingPackRatingEngine();

  Future<int> rateAll({String path = 'training_packs/library'}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, path));
    if (!dir.existsSync()) return 0;
    const reader = YamlReader();
    const writer = YamlWriter();
    var count = 0;
    for (final file in dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final map = reader.read(await file.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(map);
        final rating = _calcRating(tpl);
        final meta = Map<String, dynamic>.from(tpl.meta);
        meta['rating'] = rating;
        map['meta'] = meta;
        await writer.write(map, file.path);
        count++;
      } catch (_) {}
    }
    return count;
  }

  int _calcRating(TrainingPackTemplateV2 tpl) {
    final spots = tpl.spots;
    final valid = spots
        .where((s) => _hasHeroAction(s) && s.evalResult != null)
        .length;
    final validScore = spots.isEmpty ? 0.0 : valid * 40 / spots.length;
    final tags = <String>{for (final t in tpl.tags) t.trim().toLowerCase()}
      ..removeWhere((e) => e.isEmpty);
    final tagScore = tags.length >= 3 ? 20.0 : tags.length * (20 / 3);
    final metaScore = (tpl.meta['evScore'] != null ? 10 : 0) +
        ((tpl.audience ?? '').isNotEmpty ? 10 : 0) +
        (tpl.name.trim().isNotEmpty ? 10 : 0);
    final avgStreet = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.street).reduce((a, b) => a + b) / spots.length;
    final streetScore = avgStreet * (10 / 3);
    var rating = validScore + tagScore + metaScore + streetScore;
    if (rating < 0) rating = 0;
    if (rating > 100) rating = 100;
    return rating.round();
  }

  bool _hasHeroAction(TrainingPackSpot s) {
    final hero = s.hand.heroIndex;
    for (final list in s.hand.actions.values) {
      for (final a in list) {
        if (a.playerIndex == hero) return true;
      }
    }
    return false;
  }
}
