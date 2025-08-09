import 'package:test/test.dart';
import 'package:poker_analyzer/models/autogen_status.dart';

void main() {
  test('serializes and deserializes', () {
    final original = AutogenStatus(
      state: AutogenRunState.running,
      currentStep: 'step1',
      queueDepth: 3,
      processed: 2,
      errorsCount: 1,
      startedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1, 0, 1),
      eta: const Duration(seconds: 30),
      lastErrorMsg: 'boom',
    );
    final json = original.toJson();
    final restored = AutogenStatus.fromJson(json);
    expect(restored.state, original.state);
    expect(restored.currentStep, original.currentStep);
    expect(restored.queueDepth, original.queueDepth);
    expect(restored.processed, original.processed);
    expect(restored.errorsCount, original.errorsCount);
    expect(restored.lastErrorMsg, original.lastErrorMsg);
  });
}
