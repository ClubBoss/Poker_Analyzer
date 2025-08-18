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

  test('persistTags saves computed tags', () {
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

    final updated = const TheoryPackAutoTagger().persistTags(pack);
    expect(updated.tags, contains('icm'));
    expect(updated.tags, contains('bubble'));
    expect(updated.tags, contains('shortstack'));
    expect(pack.tags, isEmpty);
  });

  test('persistTags respects overwrite flag', () {
    final pack = TheoryPackModel(
      id: 'p',
      title: 'ICM',
      sections: const [],
      tags: const ['Custom'],
    );

    final res1 = const TheoryPackAutoTagger().persistTags(pack);
    expect(res1.tags, ['custom']);

    final res2 = const TheoryPackAutoTagger().persistTags(
      pack,
      overwrite: true,
    );
    expect(res2.tags, isNot(contains('custom')));
    expect(res2.tags, contains('icm'));
  });
}
