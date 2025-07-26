import 'package:test/test.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/services/theory_pack_auto_tagger.dart';

void main() {
  test('autoTag detects keywords', () {
    final pack = TheoryPackModel(
      id: 'p',
      title: 'ICM Bubble Play',
      sections: [
        TheorySectionModel(
          title: 'Short Stack Strategy',
          text: 'On the bubble you must play tight with a short stack.',
          type: 'info',
        ),
      ],
    );

    final tags = const TheoryPackAutoTagger().autoTag(pack);
    expect(tags, contains('ICM'));
    expect(tags, contains('bubble'));
    expect(tags, contains('shortstack'));
  });
}
