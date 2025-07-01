import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/services/pack_import_service.dart';

void main() {
  test('importFromCsv parses rows', () {
    const csv = 'Title,HeroPosition,HeroHand,StackBB,EV_BB,ICM_EV,Tags\n'
        'A,SB,AA,10,0.8,1.234,foo|bar\n'
        'B,BB,KK,10,,0.1,baz\n'
        'C,CO,22,8,,,';
    final tpl = PackImportService.importFromCsv(
      csv: csv,
      templateId: 't',
      templateName: 'Test',
    );
    expect(tpl.spots.length, 3);
    expect(tpl.spots.first.heroEv, 0.8);
    expect(tpl.spots.first.tags.contains('imported'), true);
  });
}
