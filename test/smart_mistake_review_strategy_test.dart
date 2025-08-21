import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/mistake_insight.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/smart_mistake_review_strategy.dart';
import 'package:poker_analyzer/services/skill_loss_feed_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingSpotAttempt attempt(String id) => TrainingSpotAttempt(
    spot: TrainingPackSpot(id: id, hand: HandData()),
    userAction: '',
    correctAction: '',
    evDiff: 0,
  );

  test('dominant tag triggers trainTagPack', () async {
    final insights = [
      const MistakeInsight(
        tag: MistakeTag.overfoldBtn,
        count: 8,
        evLoss: 0,
        shortExplanation: '',
        examples: [],
      ),
      const MistakeInsight(
        tag: MistakeTag.looseCallBb,
        count: 2,
        evLoss: 0,
        shortExplanation: '',
        examples: [],
      ),
    ];

    const strategy = SmartMistakeReviewStrategy();
    final decision = await strategy.decide(
      insights: insights,
      feed: const [],
      history: const [],
    );
    expect(decision.type, ReviewStrategyType.trainTagPack);
    expect(decision.targetTag, MistakeTag.overfoldBtn.label);
  });

  test('repeated spots trigger repeatSameSpots', () async {
    final ex1 = attempt('s1');
    final insights = [
      MistakeInsight(
        tag: MistakeTag.overfoldBtn,
        count: 2,
        evLoss: 0,
        shortExplanation: '',
        examples: [ex1, ex1],
      ),
    ];

    const strategy = SmartMistakeReviewStrategy();
    final decision = await strategy.decide(
      insights: insights,
      feed: const [],
      history: const [],
    );
    expect(decision.type, ReviewStrategyType.repeatSameSpots);
  });

  test('skill loss triggers recoverCluster', () async {
    final feed = [
      const SkillLossFeedItem(tag: 'sb call', urgencyScore: 1.2, trend: ''),
    ];

    const strategy = SmartMistakeReviewStrategy();
    final decision = await strategy.decide(
      insights: const [],
      feed: feed,
      history: const [],
    );
    expect(decision.type, ReviewStrategyType.recoverCluster);
    expect(decision.targetTag, 'sb call');
  });
}
