import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_track_unlock_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default track unlocked', () async {
    final unlocked = await LessonTrackUnlockEngine.instance.isUnlocked(
      'mtt_pro',
    );
    expect(unlocked, isTrue);
  });

  test('mark unlocked persists', () async {
    expect(
      await LessonTrackUnlockEngine.instance.isUnlocked('live_exploit'),
      isFalse,
    );
    await LessonTrackUnlockEngine.instance.markUnlocked('live_exploit');
    expect(
      await LessonTrackUnlockEngine.instance.isUnlocked('live_exploit'),
      isTrue,
    );
    final list = await LessonTrackUnlockEngine.instance.getUnlockedTrackIds();
    expect(list.contains('live_exploit'), isTrue);
  });
}
