import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('basic session flow', () async {
    final s1 = TrainingPackSpot(id: 'a');
    final s2 = TrainingPackSpot(id: 'b');
    final tpl = TrainingPackTemplate(id: 't', name: 't', spots: [s1, s2]);
    final service = TrainingSessionService();
    await service.startSession(tpl, persist: false);
    expect(service.currentSpot?.id, 'a');
    service.nextSpot();
    expect(service.currentSpot?.id, 'b');
    service.prevSpot();
    expect(service.currentSpot?.id, 'a');
    service.submitResult('a', 'fold', true);
    expect(service.results['a'], true);
    expect(service.correctCount, 1);
  });
}
