import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';

class SpotIssue {
  final String spotId;
  final int index;
  final String message;
  SpotIssue(this.spotId, this.index, this.message);
}

typedef SpotRule = String? Function(TrainingPackSpot s, int idx);

List<String> _extractBoard(TrainingPackSpot s) => [
  for (final street in [1, 2, 3])
    for (final a in s.hand.actions[street] ?? [])
      if (a.action == 'board' && a.customLabel?.isNotEmpty == true)
        ...(a.customLabel?.split(' ') ?? []),
];

final List<SpotRule> spotRules = [
  (s, i) => s.hand.heroCards.trim().isEmpty ? 'no hero cards' : null,
  (s, i) {
    final board = _extractBoard(s);
    if (board.isNotEmpty && ![3, 4, 5].contains(board.length)) {
      return 'invalid board';
    }
    return null;
  },
  (s, i) {
    final hasActs = s.hand.actions.values
        .expand((e) => e)
        .any((a) => a.action != 'board' && !a.generated);
    return hasActs ? null : 'no actions';
  },
  (s, i) {
    final stacks = s.hand.stacks;
    final heroStack = stacks['${s.hand.heroIndex}'];
    final stackCount = stacks.values.where((v) => v > 0).length;
    if (heroStack == null || heroStack <= 0 || stackCount < 2) {
      return 'invalid stacks';
    }
    if (heroStack < 1) return 'stack too small';
    if (heroStack > 200) return 'stack too large';
    return null;
  },
  (s, i) => s.heroEv == null || s.heroIcmEv == null ? 'missing EV/ICM' : null,
];

List<SpotIssue> validateSpot(TrainingPackSpot s, int idx) {
  final prefix = '${idx + 1}. ${s.title.isEmpty ? 'Untitled spot' : s.title}';
  final list = <SpotIssue>[];
  for (final r in spotRules) {
    final msg = r(s, idx);
    if (msg != null) list.add(SpotIssue(s.id, idx, '$prefix - $msg'));
  }
  return list;
}

List<String> validateTrainingPackTemplate(TrainingPackTemplate tpl) => [
  for (int i = 0; i < tpl.spots.length; i++)
    for (final e in validateSpot(tpl.spots[i], i)) e.message,
];
