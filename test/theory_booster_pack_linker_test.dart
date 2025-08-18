import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/services/theory_booster_pack_linker.dart';

TheoryPackModel _pack(String id, String title, String text) {
  return TheoryPackModel(
    id: id,
    title: title,
    sections: [TheorySectionModel(title: 's', text: text, type: 'tip')],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('autoLinkBoosters prefers matching short boosters', () {
    final theory = _pack(
      't',
      'Shortstack Strategy',
      List.filled(160, 'shortstack').join(' '),
    );

    final booster1 = _pack(
      'b1',
      'Shortstack Booster',
      List.filled(160, 'shortstack push').join(' '),
    );

    final booster2 = _pack(
      'b2',
      'ICM Booster',
      List.filled(320, 'icm postflop').join(' '),
    );

    const linker = TheoryBoosterPackLinker();
    final result = linker.autoLinkBoosters(theory, [booster1, booster2]);

    expect(result.length, 1);
    expect(result.first, 'b1');
  });
}
