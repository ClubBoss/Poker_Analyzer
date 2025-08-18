import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_pack_auto_fix_engine.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = BoosterPackAutoFixEngine();

  test('autoFix cleans booster pack sections', () {
    final pack = TheoryPackModel(
      id: ' b1 ',
      title: '  Booster  ',
      sections: [
        TheorySectionModel(title: '  ', text: 'x', type: 'info'),
        TheorySectionModel(title: 'Good', text: 'Word ' * 10, type: 'info'),
        TheorySectionModel(
          title: 'Tip',
          text: 'Many words here ' * 5,
          type: 'tip',
        ),
      ],
    );

    final fixed = engine.autoFix(pack);

    expect(fixed.id, 'b1');
    expect(fixed.title, 'Booster');
    // info sections should be removed
    expect(fixed.sections.length, 1);
    expect(fixed.sections.first.title, 'Tip');
    expect(fixed.sections.first.type, 'tip');
  });
}
