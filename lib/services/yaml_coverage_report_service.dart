import '../models/v2/training_pack_template_v2.dart';
import '../models/yaml_coverage_report.dart';

class YamlCoverageReportService {
  YamlCoverageReportService();

  YamlCoverageReport generate(List<TrainingPackTemplateV2> templates) {
    final tagCounts = <String, int>{};
    final audienceCounts = <String, int>{};
    final positionCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    for (final t in templates) {
      for (final tag in t.tags) {
        final v = tag.trim();
        if (v.isEmpty) continue;
        tagCounts[v] = (tagCounts[v] ?? 0) + 1;
        if (v.startsWith('position:')) {
          final p = v.substring(9);
          if (p.isNotEmpty) {
            positionCounts[p] = (positionCounts[p] ?? 0) + 1;
          }
        } else if (v.startsWith('cat:')) {
          final c = v.substring(4);
          if (c.isNotEmpty) {
            categoryCounts[c] = (categoryCounts[c] ?? 0) + 1;
          }
        }
      }
      final aud = t.audience?.trim();
      if (aud != null && aud.isNotEmpty) {
        audienceCounts[aud] = (audienceCounts[aud] ?? 0) + 1;
      }
      for (final p in t.positions) {
        final v = p.trim();
        if (v.isEmpty) continue;
        positionCounts[v] = (positionCounts[v] ?? 0) + 1;
      }
      final cat = t.category?.trim();
      if (cat != null && cat.isNotEmpty) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      }
    }
    return YamlCoverageReport(
      tags: tagCounts,
      categories: categoryCounts,
      audiences: audienceCounts,
      positions: positionCounts,
    );
  }
}
