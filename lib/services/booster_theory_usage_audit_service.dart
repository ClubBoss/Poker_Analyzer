import '../models/theory_pack_model.dart';
import '../models/theory_usage_issue.dart';
import '../models/learning_path_template_v2.dart';

/// Audits theory pack usage across learning paths.
class BoosterTheoryUsageAuditService {
  const BoosterTheoryUsageAuditService();

  /// Returns list of issues about unused or missing packs.
  List<TheoryUsageIssue> audit({
    required List<TheoryPackModel> allTheoryPacks,
    required List<LearningPathTemplateV2> allPaths,
  }) {
    final packMap = {for (final p in allTheoryPacks) p.id: p};
    final referenced = <String>{};
    for (final path in allPaths) {
      for (final stage in path.stages) {
        final id = stage.theoryPackId?.trim();
        if (id != null && id.isNotEmpty) referenced.add(id);
        for (final b in stage.boosterTheoryPackIds ?? const []) {
          final bid = b.trim();
          if (bid.isNotEmpty) referenced.add(bid);
        }
      }
    }
    final issues = <TheoryUsageIssue>[];
    for (final id in referenced) {
      final pack = packMap[id];
      if (pack == null) {
        issues.add(TheoryUsageIssue(id: id, title: '', reason: 'missing'));
      }
    }
    for (final pack in allTheoryPacks) {
      if (!referenced.contains(pack.id)) {
        issues.add(
            TheoryUsageIssue(id: pack.id, title: pack.title, reason: 'unused'));
      }
    }
    return issues;
  }
}
