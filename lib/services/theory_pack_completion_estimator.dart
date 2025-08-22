import '../models/theory_pack_model.dart';

class TheoryPackCompletionData {
  final int wordCount;
  final int estimatedMinutes;
  final double completionRatio;

  TheoryPackCompletionData({
    required this.wordCount,
    required this.estimatedMinutes,
    required this.completionRatio,
  });
}

class TheoryPackCompletionEstimator {
  TheoryPackCompletionEstimator();

  TheoryPackCompletionData estimate(
    TheoryPackModel pack, {
    Set<String> readSections = const <String>{},
  }) {
    int countWords(String text) =>
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    final words = pack.sections.fold<int>(
      0,
      (sum, s) => sum + countWords(s.text),
    );
    final minutes = words == 0 ? 0 : (words / 150).ceil();
    final totalSections = pack.sections.length;
    final readCount = pack.sections
        .where((s) => readSections.contains(s.title))
        .length;
    final ratio = totalSections > 0 ? readCount / totalSections : 0.0;

    return TheoryPackCompletionData(
      wordCount: words,
      estimatedMinutes: minutes,
      completionRatio: ratio,
    );
  }
}
