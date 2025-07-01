import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';

List<String> validateTrainingPackTemplate(TrainingPackTemplate tpl) {
  final issues = <String>[];
  for (int i = 0; i < tpl.spots.length; i++) {
    final TrainingPackSpot spot = tpl.spots[i];
    final prefix = '${i + 1}. ${spot.title.isEmpty ? 'Untitled spot' : spot.title}';
    if (spot.hand.heroCards.trim().isEmpty) {
      issues.add('$prefix - no hero cards');
    }
    final board = [
      for (final street in [1, 2, 3])
        for (final a in spot.hand.actions[street] ?? [])
          if (a.action == 'board' && a.customLabel?.isNotEmpty == true)
            ...a.customLabel!.split(' ')
    ];
    if (board.isNotEmpty && ![3, 4, 5].contains(board.length)) {
      issues.add('$prefix - invalid board');
    }
    final hasActs = spot.hand.actions.values
        .expand((e) => e)
        .any((a) => a.action != 'board' && !a.generated);
    if (!hasActs) {
      issues.add('$prefix - no actions');
    }
  }
  return issues;
}
