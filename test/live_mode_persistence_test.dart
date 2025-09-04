// ASCII-only; pure Dart test (no Flutter imports)

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_mode.dart';
import 'package:poker_analyzer/live/live_mode_persistence.dart';

class FakePersistor implements LiveModePersistor {
  TrainingMode? nextLoad;
  final List<TrainingMode> saves = <TrainingMode>[];

  @override
  Future<TrainingMode?> load() async => nextLoad;

  @override
  Future<void> save(TrainingMode mode) async {
    saves.add(mode);
  }
}

void main() {
  setUp(() {
    // Ensure default mode before each test
    LiveModeStore.set(TrainingMode.online);
  });

  group('initLiveModeFrom', () {
    test('sets mode from load() when non-null', () async {
      final p = FakePersistor()..nextLoad = TrainingMode.live;
      expect(LiveModeStore.mode, equals(TrainingMode.online));
      await initLiveModeFrom(p);
      expect(LiveModeStore.mode, equals(TrainingMode.live));
    });

    test('leaves default when load() returns null', () async {
      final p = FakePersistor()..nextLoad = null;
      expect(LiveModeStore.mode, equals(TrainingMode.online));
      await initLiveModeFrom(p);
      expect(LiveModeStore.mode, equals(TrainingMode.online));
    });
  });

  group('persistLiveModeWith', () {
    test(
      'writes current mode once, then on each change; no-op on same mode',
      () async {
        final p = FakePersistor();
        // Default is online
        final cancel = persistLiveModeWith(p);

        // Immediate write with current state
        expect(p.saves, equals(<TrainingMode>[TrainingMode.online]));

        // Change to live -> write
        LiveModeStore.set(TrainingMode.live);
        expect(
          p.saves,
          equals(<TrainingMode>[TrainingMode.online, TrainingMode.live]),
        );

        // Setting same mode -> no write
        LiveModeStore.set(TrainingMode.live);
        expect(
          p.saves,
          equals(<TrainingMode>[TrainingMode.online, TrainingMode.live]),
        );

        // Change again -> write
        LiveModeStore.set(TrainingMode.online);
        expect(
          p.saves,
          equals(<TrainingMode>[
            TrainingMode.online,
            TrainingMode.live,
            TrainingMode.online,
          ]),
        );

        // Cleanup
        cancel();
      },
    );

    test('after cancel, further changes do not trigger saves', () async {
      final p = FakePersistor();
      final cancel = persistLiveModeWith(p);

      // Baseline save
      expect(p.saves, equals(<TrainingMode>[TrainingMode.online]));

      // Cancel subscription
      cancel();

      // Further changes should not be saved
      LiveModeStore.set(TrainingMode.live);
      expect(p.saves, equals(<TrainingMode>[TrainingMode.online]));
    });
  });
}
