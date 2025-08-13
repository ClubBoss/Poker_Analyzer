import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records interactions per tag', () async {
    final service = BoosterPathHistoryService.instance;

    await service.markShown('l1', 'cbet');
    await service.markCompleted('l1', 'cbet');
    await service.markShown('l2', '3bet');

    final logs = await service.getHistory();
    expect(logs.length, 2);
    expect(logs.first.lessonId, 'l2');

    final stats = await service.getTagStats();
    final cbet = stats['cbet']!;
    expect(cbet.shownCount, 1);
    expect(cbet.completedCount, 1);
    final tbet = stats['3bet']!;
    expect(tbet.shownCount, 1);
    expect(tbet.completedCount, 0);
  });
}
