import 'package:test/test.dart';
import 'package:poker_analyzer/services/theory_pack_generator_service.dart';

void main() {
  const service = TheoryPackGeneratorService();

  test('generateForTag creates theory spot', () {
    final tpl = service.generateForTag('pushFold');
    expect(tpl.spots.length, 1);
    final spot = tpl.spots.first;
    expect(spot.type, 'theory');
    expect(spot.tags.contains('pushFold'), true);
    expect(spot.title.isNotEmpty, true);
    expect(tpl.tags.contains('pushFold'), true);
  });

  test('supports language selection', () {
    final tplEn = service.generateForTag('pushFold', lang: 'en');
    final tplRu = service.generateForTag('pushFold', lang: 'ru');
    expect(tplEn.spots.first.title, isNot(equals(tplRu.spots.first.title)));
  });
}
