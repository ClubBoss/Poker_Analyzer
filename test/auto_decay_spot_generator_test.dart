import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/decay_tag_reinforcement_event.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/auto_decay_spot_generator.dart';
import 'package:poker_analyzer/services/training_tag_performance_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<TrainingPackSpot>> spotLoader(String tag) async {
    return [
      TrainingPackSpot(
          id: '$tag-1', tags: [tag], createdAt: DateTime(2023, 1, 1)),
      TrainingPackSpot(
          id: '$tag-2', tags: [tag], createdAt: DateTime(2023, 1, 2)),
    ];
  }

  test('generate returns spots for decayed weak tags', () async {
    final now = DateTime(2023, 5, 1);
    final history = {
      'tag1': [
        DecayTagReinforcementEvent(
          tag: 'tag1',
          delta: 1,
          timestamp: now.subtract(const Duration(days: 40)),
        ),
      ],
      'tag2': [
        DecayTagReinforcementEvent(
          tag: 'tag2',
          delta: 1,
          timestamp: now.subtract(const Duration(days: 10)),
        ),
      ],
    };

    Future<List<DecayTagReinforcementEvent>> historyLoader(String tag) async =>
        history[tag] ?? <DecayTagReinforcementEvent>[];

    Future<Map<String, double>> masteryLoader() async => {
          'tag1': 0.5,
          'tag2': 0.4,
        };

    Future<Map<String, TagPerformance>> statsLoader() async => {
          'tag1': TagPerformance(
            tag: 'tag1',
            totalAttempts: 10,
            correct: 5,
            accuracy: 0.5,
            lastTrained: now.subtract(const Duration(days: 40)),
          ),
          'tag2': TagPerformance(
            tag: 'tag2',
            totalAttempts: 10,
            correct: 8,
            accuracy: 0.8,
            lastTrained: now.subtract(const Duration(days: 10)),
          ),
        };

    final gen = AutoDecaySpotGenerator(
      historyLoader: historyLoader,
      masteryLoader: masteryLoader,
      statsLoader: statsLoader,
      spotLoader: spotLoader,
    );

    final spots = await gen.generate(now: now);
    expect(spots.length, 2);
    expect(spots.first.id, 'tag1-2');
  });
}
