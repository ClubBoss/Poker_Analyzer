import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/pack_recall_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records review history and computes intervals', () async {
    final service = PackRecallStatsService.instance;
    final now = DateTime.now();
    final t1 = now.subtract(const Duration(days: 2));
    await service.recordReview('p1', t1);
    await service.recordReview('p1', now);

    final history = await service.getReviewHistory('p1');
    expect(history.length, 2);
    expect(history.first, t1);
    final avg = await service.averageReviewInterval('p1');
    expect(avg, const Duration(days: 2));
  });
}
