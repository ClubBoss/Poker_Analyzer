import '../models/mistake_tag.dart';
import '../models/training_spot_attempt.dart';
import 'mistake_tag_rules.dart';

class AutoMistakeTaggerEngine {
  const AutoMistakeTaggerEngine();

  List<MistakeTag> tag(TrainingSpotAttempt attempt) {
    final tags = <MistakeTag>[];
    for (final rule in mistakeTagRules) {
      if (rule.predicate(attempt)) tags.add(rule.tag);
    }
    return tags;
  }
}
