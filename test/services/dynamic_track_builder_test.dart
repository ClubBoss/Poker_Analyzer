import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/dynamic_track_builder.dart';
import 'package:poker_analyzer/models/learning_goal.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackSpot spot(String id, String tag, double ev) {
    final hand = HandData(
      position: HeroPosition.btn,
      heroIndex: 0,
      playerCount: 2,
      actions: {
        0: [ActionEntry(0, 0, 'push', ev: ev)],
      },
    );
    return TrainingPackSpot(id: id, tags: [tag], hand: hand);
  }

  TrainingPackTemplateV2 pack(String id, List<TrainingPackSpot> spots) {
    return TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.pushFold,
      tags: const ['cbet'],
      spots: spots,
    );
  }

  test('builds track with sorted spots', () {
    final builder = const DynamicTrackBuilder();
    final goal = LearningGoal(
      id: 'g1',
      title: '',
      description: '',
      tag: 'cbet',
      priorityScore: 1,
    );
    final p1 = pack('p1', [spot('s1', 'cbet', -0.5), spot('s2', 'cbet', 0.2)]);
    final p2 = pack('p2', [spot('s3', 'cbet', -1.0)]);

    final tracks = builder.buildTracks(goals: [goal], sourcePacks: [p1, p2]);

    expect(tracks.length, 1);
    final t = tracks.first;
    expect(t.goalId, 'g1');
    expect(t.spots.map((s) => s.id).toList(), ['s3', 's1', 's2']);
  });
}
