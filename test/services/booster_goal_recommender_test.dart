import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/booster_stats.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/weak_theory_tag.dart';
import 'package:poker_analyzer/services/booster_goal_recommender.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommend returns goals from stats', () {
    final stats = BoosterStats(
      counts: {'pushfold': 3},
      totalCompleted: 3,
      streak: 2,
      lastCompleted: DateTime.now(),
    );
    final weakTags = [
      const WeakTheoryTag(
          tag: 'pushfold', completedCount: 1, accuracy: 0.5, score: 1.0),
    ];
    final profile = PlayerProfile(tagAccuracy: {'pushfold': 0.6});

    final rec = const BoosterGoalRecommender();
    final goals =
        rec.recommend(stats: stats, weakTags: weakTags, profile: profile);

    expect(goals, isNotEmpty);
    expect(goals.first.title, contains('серии')); // streak goal
    expect(goals.last.tag, 'pushfold');
  });
}
