import 'package:collection/collection.dart';

import '../models/mistake_insight.dart';
import '../models/mistake_tag.dart';
import '../models/training_spot_attempt.dart';
import 'mistake_tag_history_service.dart';

class MistakeTagInsightsService {
  final MistakeTagHistoryService history;
  MistakeTagInsightsService({required this.history});

  static const Map<MistakeTag, String> _explanations = {
    MistakeTag.overfoldBtn: 'Too tight on BTN, folding +EV hands',
    MistakeTag.looseCallBb: 'Calling too wide from BB',
    MistakeTag.looseCallSb: 'Calling too loose from SB',
    MistakeTag.looseCallCo: 'Calling too loose from CO',
    MistakeTag.missedEvPush: 'Missed profitable shove',
    MistakeTag.missedEvCall: 'Missed profitable call',
    MistakeTag.missedEvRaise: 'Missed profitable raise',
    MistakeTag.overpush: 'Jamming too wide',
    MistakeTag.overfoldShortStack: 'Overfolding short stack',
  };

  Future<List<MistakeInsight>> generate({bool sortByEvLoss = false}) async {
    final data = history.history;
    final insights = <_InsightWrap>[];

    for (final entry in data.entries) {
      final tag =
          MistakeTag.values.firstWhereOrNull((t) => t.name == entry.key);
      if (tag == null) continue;
      final examples = entry.value.examples;
      final evLoss =
          examples.fold<double>(0, (prev, a) => prev + a.evDiff.abs());
      insights.add(
        _InsightWrap(
          insight: MistakeInsight(
            tag: tag,
            count: entry.value.count,
            shortExplanation: _explanations[tag] ?? '',
            examples: List<TrainingSpotAttempt>.from(examples),
          ),
          evLoss: evLoss,
        ),
      );
    }

    insights.sort((a, b) {
      if (sortByEvLoss) {
        return b.evLoss.compareTo(a.evLoss);
      }
      return b.insight.count.compareTo(a.insight.count);
    });

    return [for (final w in insights) w.insight];
  }
}

class _InsightWrap {
  final MistakeInsight insight;
  final double evLoss;
  _InsightWrap({required this.insight, required this.evLoss});
}
