import 'package:test/test.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/services/theory_pack_review_status_engine.dart';

void main() {
  const engine = TheoryPackReviewStatusEngine();

  test('getStatus returns approved for complete pack', () {
    final text = List.filled(150, 'word').join(' ');
    final pack = TheoryPackModel(
      id: 't1',
      title: 'Title',
      sections: [TheorySectionModel(title: 's', text: text, type: 'info')],
    );
    expect(engine.getStatus(pack), ReviewStatus.approved);
  });

  test('getStatus returns rewrite for missing title', () {
    final pack = TheoryPackModel(
      id: 't2',
      title: '',
      sections: [
        const TheorySectionModel(title: 's', text: 'a b c', type: 'info'),
      ],
    );
    expect(engine.getStatus(pack), ReviewStatus.rewrite);
  });

  test('getStatus returns draft otherwise', () {
    final pack = TheoryPackModel(
      id: 't3',
      title: 'T',
      sections: [
        const TheorySectionModel(
          title: 's',
          text: 'few words here',
          type: 'info',
        ),
      ],
    );
    expect(engine.getStatus(pack), ReviewStatus.draft);
  });
}
