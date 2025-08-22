import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/pack_library_rating_report.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_rating_engine.dart';

class PackLibraryRatingEngine {
  PackLibraryRatingEngine();

  Future<PackLibraryRatingReport> rateLibrary(
    List<TrainingPackTemplateV2> packs, {
    bool save = true,
    String path = 'training_packs/library/rating_report.json',
  }) async {
    final ratings = <(TrainingPackTemplateV2, int)>[];
    const engine = TrainingPackRatingEngine();
    for (final p in packs) {
      final r = engine.rate(p).score;
      ratings.add((p, r));
    }
    ratings.sort((a, b) => b.$2.compareTo(a.$2));
    final top = [for (final e in ratings.take(10)) (e.$1.id, e.$2)];
    final audMap = <String, List<int>>{};
    final tagMap = <String, List<int>>{};
    for (final (p, s) in ratings) {
      final a = p.audience ?? 'Unknown';
      audMap.putIfAbsent(a, () => []).add(s);
      for (final t in p.tags) {
        final tag = t.trim();
        if (tag.isEmpty) continue;
        tagMap.putIfAbsent(tag, () => []).add(s);
      }
    }
    final audAvg = <String, double>{};
    for (final e in audMap.entries) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      audAvg[e.key] = double.parse(avg.toStringAsFixed(2));
    }
    final tags = <String, (double, int)>{};
    for (final e in tagMap.entries) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      tags[e.key] = (double.parse(avg.toStringAsFixed(2)), e.value.length);
    }
    final report = PackLibraryRatingReport(
      topRatedPacks: top,
      averageScoresByAudience: audAvg,
      tagInsights: tags,
    );
    if (save) {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(p.join(docs.path, path))..createSync(recursive: true);
      await file.writeAsString(jsonEncode(report.toJson()), flush: true);
    }
    return report;
  }
}
