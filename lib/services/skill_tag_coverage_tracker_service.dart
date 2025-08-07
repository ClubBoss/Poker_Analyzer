import '../models/skill_tag_coverage_report.dart';
import 'training_pack_library_service.dart';
import 'skill_tag_coverage_tracker.dart';

/// Evaluates how many spots reference each skill tag across the
/// training pack library.
class SkillTagCoverageTrackerService {
  static final SkillTagCoverageTrackerService instance =
      SkillTagCoverageTrackerService();

  final TrainingPackLibraryService library;
  final Set<String> allSkillTags;
  final int underrepresentedThreshold;
  final SkillTagCoverageTracker _tracker;

  SkillTagCoverageTrackerService({
    TrainingPackLibraryService? library,
    Set<String>? allSkillTags,
    this.underrepresentedThreshold = 5,
    SkillTagCoverageTracker? tracker,
  })  : library = library ?? TrainingPackLibraryService(),
        allSkillTags = allSkillTags ?? const {},
        _tracker = tracker ?? SkillTagCoverageTracker();

  /// Returns current tag usage statistics.
  Map<String, int> getTagStats() =>
      Map<String, int>.from(_tracker.skillTagCounts);

  /// Resets the underlying tracker.
  void reset() => _tracker.reset();

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
