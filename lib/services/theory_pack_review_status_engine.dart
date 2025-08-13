import '../models/theory_pack_model.dart';

/// Status of theory pack review.
enum ReviewStatus { draft, approved, rewrite }

/// Provides heuristics for determining review status of a theory pack.
class TheoryPackReviewStatusEngine {
  const TheoryPackReviewStatusEngine();

  /// Returns review status for [pack] based on simple heuristics.
  ReviewStatus getStatus(TheoryPackModel pack) {
    final hasTitle = pack.title.trim().isNotEmpty;
    final wordCount =
        pack.sections.fold<int>(0, (sum, s) => sum + _wordCount(s.text));
    if (hasTitle && pack.sections.isNotEmpty && wordCount >= 150) {
      return ReviewStatus.approved;
    }
    if (!hasTitle || wordCount < 50) {
      return ReviewStatus.rewrite;
    }
    return ReviewStatus.draft;
  }

  int _wordCount(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.length;
  }
}
