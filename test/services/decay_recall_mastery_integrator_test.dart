import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/decay_tag_reinforcement_event.dart';
import 'package:poker_analyzer/services/decay_recall_mastery_integrator.dart';
import 'package:poker_analyzer/services/mastery_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('applies negative delta when no recent reinforcement', () async {
    final store = MasteryPersistenceService();
    await store.save({'push': 0.5});
    final integrator = DecayRecallMasteryIntegrator(
      historyLoader: (_) async => <DecayTagReinforcementEvent>[],
      persistence: store,
    );
    await integrator.integrate(now: DateTime(2024, 1, 10));
    final map = await store.load();
    expect(map['push'], closeTo(0.48, 0.0001));
  });

  test('positive adjustments accumulate and are capped', () async {
    final store = MasteryPersistenceService();
    await store.save({'push': 0.5});
    final events = [
      for (int i = 0; i < 7; i++)
        DecayTagReinforcementEvent(
          tag: 'push',
          delta: 0.01,
          timestamp: DateTime(2024, 1, 10).subtract(Duration(days: i)),
        ),
    ];
    final integrator = DecayRecallMasteryIntegrator(
      historyLoader: (_) async => events,
      persistence: store,
    );
    await integrator.integrate(now: DateTime(2024, 1, 10));
    final map = await store.load();
    expect(map['push'], closeTo(0.55, 0.0001));
  });
}
