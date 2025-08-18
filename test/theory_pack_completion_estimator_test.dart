import 'package:test/test.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/services/theory_pack_completion_estimator.dart';

void main() {
  const estimator = TheoryPackCompletionEstimator();

  test('estimate returns word count, time and ratio', () {
    final text = List.filled(100, 'word').join(' ');
    final pack = TheoryPackModel(
      id: 't',
      title: 'T',
      sections: [
        TheorySectionModel(title: 'a', text: text, type: 'info'),
        TheorySectionModel(title: 'b', text: text, type: 'info'),
      ],
    );

    final data = estimator.estimate(pack, readSections: {'a'});

    expect(data.wordCount, 200);
    expect(data.estimatedMinutes, 2);
    expect(data.completionRatio, closeTo(0.5, 0.001));
  });
}
