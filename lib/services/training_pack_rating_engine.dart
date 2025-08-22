import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/pack_rating_report.dart';

class TrainingPackRatingEngine {
  TrainingPackRatingEngine();

  PackRatingReport rate(TrainingPackTemplateV2 pack) {
    final warnings = <String>[];
    final insights = <String>[];
    final positions = <String>{
      ...pack.positions,
      for (final s in pack.spots) s.hand.position.name,
    }..removeWhere((e) => e.trim().isEmpty);
    final posScore = (positions.length >= 5 ? 20 : positions.length * 4)
        .toDouble();
    if (positions.length < 5) warnings.add('low_position_coverage');
    insights.add('positions:${positions.length}');

    final prCounts = <int, int>{};
    for (final s in pack.spots) {
      prCounts[s.priority] = (prCounts[s.priority] ?? 0) + 1;
    }
    double spread = 0;
    final avg = pack.spots.isEmpty ? 0 : pack.spots.length / prCounts.length;
    for (final c in prCounts.values) {
      spread += (c - avg).abs();
    }
    final prScore = prCounts.isEmpty
        ? 0
        : (20 - (spread / pack.spots.length) * 20).clamp(0, 20);
    if (prScore < 10) warnings.add('priority_bias');
    insights.add('priority:${prScore.toStringAsFixed(1)}');

    final seen = <String>{};
    final valid = <String>{};
    for (final s in pack.spots) {
      final key = _spotKey(s);
      seen.add(key);
      if (_hasHeroAction(s) && s.evalResult != null) valid.add(key);
    }
    final validScore = pack.spots.isEmpty
        ? 0
        : (valid.length * 20 / pack.spots.length).clamp(0, 20);
    if (valid.length < pack.spots.length) warnings.add('invalid_or_duplicate');
    insights.add('valid:${valid.length}/${pack.spots.length}');

    final groups = <String>{};
    for (final s in pack.spots) {
      final g = _handGroup(s.hand.heroCards);
      if (g.isNotEmpty) groups.add(g);
    }
    final groupScore = (groups.length >= 10 ? 20 : groups.length * 2)
        .toDouble();
    if (groups.length < 10) warnings.add('low_hand_diversity');
    insights.add('groups:${groups.length}');

    final content = '${pack.name} ${pack.goal} ${pack.description}'
        .toLowerCase();
    final rel = [
      for (final t in pack.tags)
        if (content.contains(t.toLowerCase())) t,
    ];
    final tagScore = pack.tags.isEmpty
        ? 0
        : (rel.length * 20 / pack.tags.length).clamp(0, 20);
    if (tagScore < 10) warnings.add('weak_tag_relevance');
    insights.add('tags:${rel.length}/${pack.tags.length}');

    var score = posScore + prScore + validScore + groupScore + tagScore;
    if (score < 0) score = 0;
    if (score > 100) score = 100;
    return PackRatingReport(
      score: score.round(),
      warnings: warnings,
      insights: insights,
    );
  }

  Future<int> rateAll({String path = 'training_packs/library'}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, path));
    if (!dir.existsSync()) return 0;
    const reader = YamlReader();
    const writer = YamlWriter();
    var count = 0;
    for (final file
        in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await file.readAsString();
        final map = reader.read(yaml);
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
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
    return rate(tpl).score;
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

  String _spotKey(TrainingPackSpot s) {
    final map = Map<String, dynamic>.from(s.toJson());
    map.remove('editedAt');
    map.remove('createdAt');
    map.remove('evalResult');
    map.remove('correctAction');
    map.remove('explanation');
    return map.toString();
  }

  String _handGroup(String cards) {
    final ranks = cards.replaceAll(RegExp('[^AKQJT98765432]'), '');
    if (ranks.length < 2) return '';
    final r1 = ranks[0];
    final r2 = ranks[1];
    if (r1 == r2) return '$r1$r2';
    final suits = cards.replaceAll(RegExp('[AKQJT98765432]'), '');
    if (suits.length >= 2 && suits[0] == suits[1]) {
      return '$r1$r2s';
    }
    return '$r1$r2o';
  }
}
