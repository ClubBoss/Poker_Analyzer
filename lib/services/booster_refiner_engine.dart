import 'dart:io';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class BoosterRefinerEngine {
  BoosterRefinerEngine();

  /// Refines all booster packs in [dir].
  ///
  /// Returns the number of packs updated.
  Future<int> refineAll({String dir = 'yaml_out/boosters'}) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return 0;
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    var count = 0;
    for (final file in files) {
      try {
        final yaml = await file.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlString(yaml);
        final meta = tpl.meta;
        final generatedBy = meta['generatedBy']?.toString();
        if (generatedBy != 'BoosterSuggestionEngine v1') continue;
        final tag = (meta['tag']?.toString() ?? '').toLowerCase();
        final refined = refine(tpl, tag);
        await file.writeAsString(refined.toYamlString());
        count++;
      } catch (_) {}
    }
    return count;
  }

  /// Refines a single [pack] assuming it was generated for [tag].
  TrainingPackTemplateV2 refine(TrainingPackTemplateV2 pack, String tag) {
    final ids = <String>{};
    final spots = <TrainingPackSpot>[];
    for (final s in pack.spots) {
      if (ids.add(s.id)) spots.add(s);
    }
    final explanation = 'Рекомендовано для изучения темы: $tag';
    for (final s in spots) {
      s.explanation = explanation;
    }
    pack.spots
      ..clear()
      ..addAll(spots);
    pack.spotCount = spots.length;
    final meta = Map<String, dynamic>.from(pack.meta);
    meta['tag'] = tag;
    meta['generatedBy'] = 'BoosterSuggestionEngine v1';
    meta['version'] = meta['version'] ?? '1';
    pack.meta
      ..clear()
      ..addAll(meta);
    return pack;
  }
}
