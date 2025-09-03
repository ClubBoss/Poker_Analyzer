// Pure Dart tests for LiveModeStore

import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_mode.dart';

void main() {
  setUp(() {
    // Ensure a clean mode before each test
    LiveModeStore.set(TrainingMode.online);
  });

  test('default is TrainingMode.online and isLive == false', () {
    expect(LiveModeStore.mode, TrainingMode.online);
    expect(LiveModeStore.isLive, isFalse);
  });

  test('toggle() switches to live then back to online', () {
    LiveModeStore.toggle();
    expect(LiveModeStore.mode, TrainingMode.live);
    expect(LiveModeStore.isLive, isTrue);

    LiveModeStore.toggle();
    expect(LiveModeStore.mode, TrainingMode.online);
    expect(LiveModeStore.isLive, isFalse);
  });

  test('set(live) notifies once; removing listener stops notifications', () {
    var count = 0;
    void listener(TrainingMode m) {
      count += 1;
    }

    LiveModeStore.addListener(listener);
    addTearDown(() => LiveModeStore.removeListener(listener));

    // From online -> live triggers once
    LiveModeStore.set(TrainingMode.live);
    expect(count, 1);

    // Remove listener; further changes should not notify
    LiveModeStore.removeListener(listener);
    LiveModeStore.set(TrainingMode.online);
    LiveModeStore.set(TrainingMode.live);
    expect(count, 1);
  });

  test('re-setting same mode does not notify', () {
    var count = 0;
    void listener(TrainingMode m) {
      count += 1;
    }

    LiveModeStore.addListener(listener);
    addTearDown(() => LiveModeStore.removeListener(listener));

    // Change once -> notify once
    LiveModeStore.set(TrainingMode.live);
    expect(count, 1);

    // Setting to same mode should not notify
    LiveModeStore.set(TrainingMode.live);
    expect(count, 1);
  });
}
