import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/training_pack_performance_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('evaluates performance requirements', () async {
    SharedPreferences.setMockInitialValues({
      'tpl_stat_prev': '{"accuracy":0.82,"last":0}',
      'tpl_prog_prev': 49,
    });
    final service = TrainingPackPerformanceTrackerService.instance;
    expect(
      await service.meetsRequirements('prev',
          requiredAccuracy: 0.8, minHands: 50),
      isTrue,
    );
    expect(
      await service.meetsRequirements('prev',
          requiredAccuracy: 0.85, minHands: 50),
      isFalse,
    );
    expect(
      await service.meetsRequirements('prev',
          requiredAccuracy: 0.8, minHands: 60),
      isFalse,
    );
  });
}
