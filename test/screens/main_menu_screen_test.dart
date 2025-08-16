import 'package:test/test.dart';
import 'package:poker_analyzer/screens/main_menu_screen.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('loadReplaySpots picks last valid snapshot', () async {
    final state = MainMenuScreen().createState();
    final lines = [
      '{"spots": [{"k":0,"h":"22","p":"CO","s":"5","a":"fold"}]}',
      '{"foo": 1}',
      '',
      '{"spots": []}',
      '{"spots": [{"k":0,"h":"AA","p":"BTN","s":"10","a":"push"}]}',
      '',
    ];
    await (state as dynamic).loadReplaySpotsForTest(lines);
    final spots = (state as dynamic).replaySpotsForTest as List<UiSpot>;
    expect(spots.length, 1);
    final spot = spots.first;
    expect(spot.kind, SpotKind.l2_open_fold);
    expect(spot.hand, 'AA');
    expect(spot.pos, 'BTN');
    expect(spot.stack, '10');
    expect(spot.action, 'push');
  });
}
