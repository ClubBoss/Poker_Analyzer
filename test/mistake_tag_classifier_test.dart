import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/services/mistake_tag_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingSpotAttempt _attempt() {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(heroCards: 'As Ad', position: HeroPosition.btn),
    );
    return TrainingSpotAttempt(
      spot: spot,
      userAction: 'fold',
      correctAction: 'push',
      evDiff: -3,
    );
  }

  test('classifies major overfold', () {
    final cls = const MistakeTagClassifier().classify(_attempt());
    expect(cls, isNotNull);
    expect(cls!.tag, MistakeTag.overfoldBtn);
    expect(cls.severity, greaterThan(0.8));
  });

  test('provides theory tags for overfold', () {
    final tags = const MistakeTagClassifier().classifyTheory(_attempt());
    expect(tags, contains('pushRange'));
    expect(tags, contains('overfold'));
  });
}
