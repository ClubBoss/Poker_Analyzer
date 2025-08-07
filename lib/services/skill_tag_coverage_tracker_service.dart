import '../models/skill_tag_coverage_report.dart';
import 'training_pack_library_service.dart';

/// Evaluates how many spots reference each skill tag across the
/// training pack library.
class SkillTagCoverageTrackerService {
  final TrainingPackLibraryService library;
  final Set<String> allSkillTags;
  final int underrepresentedThreshold;

  SkillTagCoverageTrackerService({
    TrainingPackLibraryService? library,
    Set<String>? allSkillTags,
    this.underrepresentedThreshold = 5,
  }) : library = library ?? TrainingPackLibraryService(),
       allSkillTags = allSkillTags ?? const {};

  /// Generates a coverage report for all packs in the library.
  Future<SkillTagCoverageReport> generateReport() async {
    final packs = await library.getAllPacks();
    final counts = <String, int>{};
    for (final pack in packs) {
      for (final spot in pack.spots) {
        for (final tag in spot.tags) {
          final norm = tag.trim().toLowerCase();
          if (norm.isEmpty) continue;
          counts[norm] = (counts[norm] ?? 0) + 1;
        }
      }
    }
    final underrepresented = <String>[
      for (final tag in allSkillTags)
        if ((counts[tag] ?? 0) < underrepresentedThreshold) tag,
    ];
    return SkillTagCoverageReport(
      tagCounts: counts,
      underrepresentedTags: underrepresented,
    );
  }
}
