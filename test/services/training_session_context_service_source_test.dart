import 'package:poker_analyzer/services/training_session_context_service.dart';
import 'package:test/test.dart';

void main() {
  test('uses provided source', () {
    final svc = TrainingSessionContextService();
    final fp = svc.start(
        packId: 'p1', trainingType: 'standard', source: 'starter_banner');
    expect(fp.source, 'starter_banner');
  });

  test('defaults source to manual', () {
    final svc = TrainingSessionContextService();
    final fp = svc.start(packId: 'p1', trainingType: 'standard');
    expect(fp.source, 'manual');
  });
}
