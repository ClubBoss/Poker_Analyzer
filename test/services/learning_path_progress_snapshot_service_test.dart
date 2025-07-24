import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_progress_snapshot.dart';
import 'package:poker_analyzer/services/learning_path_progress_snapshot_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load snapshot', () async {
    final service = LearningPathProgressSnapshotService();
    final snap = LearningPathProgressSnapshot(
      pathId: 'p1',
      stageId: 's1',
      subProgress: {'sub1': 0.5},
      handsPlayed: 10,
      accuracy: 80.0,
    );
    await service.save('p1', snap);
    final loaded = await service.load('p1');
    expect(loaded, isNotNull);
    expect(loaded!.pathId, 'p1');
    expect(loaded.stageId, 's1');
    expect(loaded.subProgress['sub1'], 0.5);
    expect(loaded.handsPlayed, 10);
    expect(loaded.accuracy, 80.0);
  });
}
