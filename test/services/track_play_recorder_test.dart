import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/track_play_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('record start and completion', () async {
    SharedPreferences.setMockInitialValues({});
    final recorder = TrackPlayRecorder.instance;

    await recorder.recordStart('g1');
    var history = await recorder.getHistory();
    expect(history.length, 1);
    expect(history.first.goalId, 'g1');
    expect(history.first.completedAt, isNull);

    await recorder.recordCompletion('g1', accuracy: 0.8, mistakes: 2);
    history = await recorder.getHistory();
    expect(history.length, 1);
    expect(history.first.completedAt, isNotNull);
    expect(history.first.accuracy, 0.8);
    expect(history.first.mistakeCount, 2);
  });

  test('keeps max 100 entries', () async {
    SharedPreferences.setMockInitialValues({});
    final recorder = TrackPlayRecorder.instance;
    for (var i = 0; i < 120; i++) {
      await recorder.recordStart('g$i');
    }
    final history = await recorder.getHistory();
    expect(history.length, 100);
    expect(history.first.goalId, 'g119');
    expect(history.last.goalId, 'g20');
  });
}
