import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'yaml_pack_rating_engine.dart';

class TrainingPackRankingEngine {
  const TrainingPackRankingEngine();

  static const _w1 = 0.2;
  static const _w2 = 0.2;
  static const _w3 = 0.2;
  static const _w4 = 0.2;
  static const _w5 = 0.2;

  Future<int> computeRankings({String path = 'training_packs/library'}) async {
    if (!kDebugMode) return 0;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return 0;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList();
    const reader = YamlReader();
    const writer = YamlWriter();
    final templates = <TrainingPackTemplateV2>[];
    final paths = <TrainingPackTemplateV2, String>{};
    for (final f in files) {
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        templates.add(tpl);
        paths[tpl] = f.path;
      } catch (_) {}
    }
    if (templates.isEmpty) return 0;
    final tagCounts = <String, int>{};
    final tagSets = <String, int>{};
    var maxSpots = 0;
    final evs = <double>[];
    final icms = <double>[];
    final covs = <double>[];
    for (final t in templates) {
      maxSpots = t.spotCount > maxSpots ? t.spotCount : maxSpots;
      evs.add((t.meta['evScore'] as num?)?.toDouble() ?? 0);
      icms.add((t.meta['icmScore'] as num?)?.toDouble() ?? 0);
      covs.add(t.coveragePercent ?? 0);
      final tags = <String>{for (final x in t.tags) x.trim().toLowerCase()}
        ..removeWhere((e) => e.isEmpty);
      final key = tags.isEmpty ? '' : (tags.toList()..sort()).join('|');
      tagSets[key] = (tagSets[key] ?? 0) + 1;
      for (final tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final maxTag = tagCounts.isEmpty
        ? 0
        : tagCounts.values.reduce((a, b) => a > b ? a : b);
    final minEv = evs.reduce((a, b) => a < b ? a : b);
    final maxEv = evs.reduce((a, b) => a > b ? a : b);
    final minIcm = icms.reduce((a, b) => a < b ? a : b);
    final maxIcm = icms.reduce((a, b) => a > b ? a : b);
    final maxCov = covs.isEmpty ? 0.0 : covs.reduce((a, b) => a > b ? a : b);
    final list = <Map<String, dynamic>>[];
    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      final evNorm = maxEv == minEv ? 0 : (evs[i] - minEv) / (maxEv - minEv);
      final icmNorm =
          maxIcm == minIcm ? 0 : (icms[i] - minIcm) / (maxIcm - minIcm);
      final covNorm = maxCov == 0 ? 0 : covs[i] / maxCov;
      final tags = <String>{for (final x in t.tags) x.trim().toLowerCase()}
        ..removeWhere((e) => e.isEmpty);
      double tagPop = 0;
      if (tags.isNotEmpty && maxTag > 0) {
        for (final tag in tags) {
          tagPop += (tagCounts[tag] ?? 0) / maxTag;
        }
        tagPop /= tags.length;
      }
      final key = tags.isEmpty ? '' : (tags.toList()..sort()).join('|');
      final uniqNorm = 1 / (tagSets[key] ?? 1);
      final lenNorm = maxSpots == 0 ? 0 : t.spotCount / maxSpots;
      final rank = _w1 * evNorm +
          _w2 * icmNorm +
          _w3 * covNorm +
          _w4 * uniqNorm +
          _w5 * lenNorm;
      final map = t.toJson();
      final meta = Map<String, dynamic>.from(map['meta'] as Map? ?? {});
      meta['rankScore'] = double.parse(rank.toStringAsFixed(4));
      map['meta'] = meta;
      await writer.write(map, paths[t]!);
      list.add(map);
    }
    list.sort((a, b) {
      final ar = (a['meta']?['rankScore'] as num?)?.toDouble() ?? 0;
      final br = (b['meta']?['rankScore'] as num?)?.toDouble() ?? 0;
      return br.compareTo(ar);
    });
    final indexFile = File(p.join(dir.path, 'library_index.json'));
    await indexFile.create(recursive: true);
    await indexFile.writeAsString(jsonEncode(list), flush: true);
    return templates.length;
  }

  double rank(TrainingPackTemplateV2 pack, List<TrainingPackTemplateV2> all) {
    final ratings = [
      for (final p in all) const YamlPackRatingEngine().rate(p).toDouble()
    ];
    if (ratings.isEmpty) return 0;
    ratings.sort();
    final median = ratings.length.isOdd
        ? ratings[ratings.length ~/ 2]
        : (ratings[ratings.length ~/ 2 - 1] + ratings[ratings.length ~/ 2]) / 2;
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    final sd =
        sqrt(ratings.fold(0, (s, v) => s + pow(v - avg, 2)) / ratings.length);
    if (sd == 0) return 0.5;
    final r = const YamlPackRatingEngine().rate(pack).toDouble();
    final z = (r - median) / sd;
    return 1 / (1 + exp(-z));
  }

  Map<String, double> rankAll(List<TrainingPackTemplateV2> packs) {
    final result = <String, double>{};
    for (final p in packs) {
      final rankScore = rank(p, packs);
      p.meta['rankScore'] = double.parse(rankScore.toStringAsFixed(4));
      result[p.id] = rankScore;
    }
    return result;
  }
}
