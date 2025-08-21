import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_import_service.dart';

void main() {
  test('importFromCsv parses rows', () {
    const csv =
        'Title,HeroPosition,HeroHand,StackBB,StacksBB,HeroIndex,CallsMask,EV_BB,ICM_EV,Tags\n'
        'A,SB,AA,10,,0,,0.8,1.234,foo|bar\n'
        'B,BB,KK,10,,0,,,0.1,baz\n'
        'C,CO,22,8,,0,,,,';
    final tpl = PackImportService.importFromCsv(
      csv: csv,
      templateId: 't',
      templateName: 'Test',
    );
    expect(tpl.spots.length, 3);
    expect(tpl.spots.first.heroEv, 0.8);
    expect(tpl.spots.first.tags.contains('imported'), true);
  });

  test('stacks and calls mask', () {
    const csv =
        'Title,HeroPosition,HeroHand,StacksBB,HeroIndex,CallsMask\n'
        'A,SB,AA,5/10/20,1,010\n';
    final tpl = PackImportService.importFromCsv(
      csv: csv,
      templateId: 'x',
      templateName: 'X',
    );
    final spot = tpl.spots.single;
    expect(spot.hand.playerCount, 3);
    final actions = spot.hand.actions[0]!;
    expect(actions.firstWhere((a) => a.playerIndex == 1).action, 'push');
    expect(actions.firstWhere((a) => a.playerIndex == 2).action, 'call');
  });
}
