import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/services/icm_scenario_library_injector.dart';

void main() {
  group('ICMScenarioLibraryInjector', () {
    test('injects spots for final table tag', () {
      final model = TrainingPackModel(
        id: 'p1',
        title: 'Pack',
        spots: [TrainingPackSpot(id: 's1', hand: HandData())],
        tags: ['finalTable'],
        metadata: {},
      );
      final injector = ICMScenarioLibraryInjector();

      final result = injector.injectICMSpots(model);
      expect(result.spots.length, greaterThan(1));
      final injected = result.spots.first;
      expect(injected.tags.contains('icm'), isTrue);
      expect(injected.isInjected, isTrue);
    });

    test('does nothing when stage not matched', () {
      final model = TrainingPackModel(
        id: 'p1',
        title: 'Pack',
        spots: [TrainingPackSpot(id: 's1', hand: HandData())],
        tags: ['early'],
        metadata: {},
      );
      final injector = ICMScenarioLibraryInjector();
      final result = injector.injectICMSpots(model);
      expect(result.spots.length, 1);
    });
  });
}
