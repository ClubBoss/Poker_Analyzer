import 'package:test/test.dart';
import 'package:poker_analyzer/screens/v2/training_pack_play_screen_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

void main() {
  final template = TrainingPackTemplate(id: 't', name: 'T');
  final screen = TrainingPackPlayScreenV2(template: template, spots: const []);
  final state = screen.createState() as dynamic;

  test('normalize maps shove/all-in to push', () {
    expect(state._normalize('shove'), 'push');
    expect(state._normalize('all-in'), 'push');
    expect(state._normalize('fold'), 'fold');
  });

  test('_actsForStreet returns [] for OOR', () {
    final spot = TrainingPackSpot(
      id: 's',
      hand: HandData(
        actions: {
          0: [ActionEntry(0, 0, 'push'), ActionEntry(0, 1, 'fold')],
        },
      ),
    );
    final res = state._actsForStreet(spot, 5) as List<ActionEntry>;
    expect(res, isEmpty);
  });
}
