import '../models/mistake_tag.dart';
import '../models/training_spot_attempt.dart';
import '../models/v2/hero_position.dart';

typedef MistakeTagPredicate = bool Function(TrainingSpotAttempt attempt);

class MistakeTagRule {
  final MistakeTag tag;
  final MistakeTagPredicate predicate;
  MistakeTagRule(this.tag, this.predicate);
}

final List<MistakeTagRule> mistakeTagRules = [
  MistakeTagRule(
    MistakeTag.overfoldBtn,
    (a) =>
        a.spot.hand.position == HeroPosition.btn &&
        a.userAction.toLowerCase() == 'fold' &&
        a.correctAction.toLowerCase() != 'fold',
  ),
  MistakeTagRule(
    MistakeTag.looseCallBb,
    (a) =>
        a.spot.hand.position == HeroPosition.bb &&
        a.userAction.toLowerCase() == 'call' &&
        a.correctAction.toLowerCase() == 'fold',
  ),
  MistakeTagRule(
    MistakeTag.looseCallSb,
    (a) =>
        a.spot.hand.position == HeroPosition.sb &&
        a.userAction.toLowerCase() == 'call' &&
        a.correctAction.toLowerCase() == 'fold',
  ),
  MistakeTagRule(
    MistakeTag.looseCallCo,
    (a) =>
        a.spot.hand.position == HeroPosition.co &&
        a.userAction.toLowerCase() == 'call' &&
        a.correctAction.toLowerCase() == 'fold',
  ),
  MistakeTagRule(
    MistakeTag.missedEvPush,
    (a) =>
        a.correctAction.toLowerCase() == 'push' &&
        a.userAction.toLowerCase() != 'push' &&
        a.evDiff > 0,
  ),
  MistakeTagRule(
    MistakeTag.missedEvCall,
    (a) =>
        a.correctAction.toLowerCase() == 'call' &&
        a.userAction.toLowerCase() != 'call' &&
        a.evDiff > 0,
  ),
  MistakeTagRule(
    MistakeTag.missedEvRaise,
    (a) =>
        a.correctAction.toLowerCase() == 'raise' &&
        a.userAction.toLowerCase() != 'raise' &&
        a.evDiff > 0,
  ),
  MistakeTagRule(
    MistakeTag.overpush,
    (a) =>
        a.userAction.toLowerCase() == 'push' &&
        a.correctAction.toLowerCase() == 'fold' &&
        a.evDiff < 0,
  ),
  MistakeTagRule(MistakeTag.overfoldShortStack, (a) {
    final heroIndex = a.spot.hand.heroIndex;
    final stack = a.spot.hand.stacks['$heroIndex'] ?? 0;
    return stack <= 10 &&
        a.userAction.toLowerCase() == 'fold' &&
        a.correctAction.toLowerCase() != 'fold';
  }),
];
