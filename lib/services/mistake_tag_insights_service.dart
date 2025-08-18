import '../models/mistake_tag.dart';
import '../models/mistake_insight.dart';
import '../models/training_spot_attempt.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import 'mistake_tag_history_service.dart';

class MistakeTagInsightsService {
  static const Map<MistakeTag, String> _explanations = {
    MistakeTag.overfoldBtn: 'Too tight on BTN, folding +EV hands',
    MistakeTag.looseCallBb: 'Calling too wide from BB',
    MistakeTag.looseCallSb: 'Calling too wide from SB',
    MistakeTag.looseCallCo: 'Calling too wide from CO',
    MistakeTag.missedEvPush: 'Skipped profitable push',
    MistakeTag.missedEvCall: 'Skipped profitable call',
    MistakeTag.missedEvRaise: 'Missed value raise',
    MistakeTag.overpush: 'Pushing too many hands',
    MistakeTag.overfoldShortStack: 'Folding too much with short stack',
  };

  final int exampleCount;
  const MistakeTagInsightsService({this.exampleCount = 3});

  Future<List<MistakeInsight>> buildInsights({
    bool sortByEvLoss = false,
  }) async {
    final freq = await MistakeTagHistoryService.getTagsByFrequency();
    final result = <MistakeInsight>[];
    final evLossMap = <MistakeTag, double>{};

    for (final entry in freq.entries) {
      final recent = await MistakeTagHistoryService.getRecentMistakesByTag(
        entry.key,
        limit: exampleCount,
      );
      final examples = <TrainingSpotAttempt>[];
      double loss = 0;
      for (final r in recent) {
        loss += r.evDiff < 0 ? -r.evDiff : 0;
        examples.add(
          TrainingSpotAttempt(
            spot: TrainingPackSpot(id: r.spotId, hand: HandData()),
            userAction: '',
            correctAction: '',
            evDiff: r.evDiff,
          ),
        );
      }
      evLossMap[entry.key] = loss;
      result.add(
        MistakeInsight(
          tag: entry.key,
          count: entry.value,
          evLoss: loss,
          shortExplanation: _explanations[entry.key] ?? '',
          examples: examples,
        ),
      );
    }

    if (sortByEvLoss) {
      result.sort((a, b) => b.evLoss.compareTo(a.evLoss));
    } else {
      result.sort((a, b) => b.count.compareTo(a.count));
    }
    return result;
  }
}
