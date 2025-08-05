import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_session_context_service.dart';

void main() {
  test('start stores current fingerprint', () {
    final service = TrainingSessionContextService();
    final fp = service.start(
      packId: 'pack1',
      trainingType: 'manual',
      includedTags: ['tagA'],
      involvedLines: ['line1'],
      source: 'historyReplay',
    );
    expect(fp.sessionId, isNotEmpty);
    expect(service.getCurrentSessionFingerprint(), equals(fp));
  });
}
