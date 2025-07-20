import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/yaml_lesson_track_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('loadTracksFromAssets loads sample track', () async {
    final loader = YamlLessonTrackLoader.instance;
    final tracks = await loader.loadTracksFromAssets();
    final sample = tracks.firstWhere((t) => t.id == 'yaml_sample');
    expect(sample.unlockCondition?.minXp, 500);
    expect(sample.unlockCondition?.requiredTags.contains('push_fold'), isTrue);
  });
}
