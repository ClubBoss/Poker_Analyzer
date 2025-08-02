import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/track_unlock_reason_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tracker = SkillTreeNodeProgressTracker.instance;
  final service = TrackUnlockReasonService.instance;

  setUp(() async {
    await tracker.resetForTest();
  });

  test('returns message when track is locked', () async {
    final reason = await service.getUnlockReason('live_exploit');
    expect(reason, isNotNull);
    expect(reason, contains('MTT Pro Track'));
  });

  test('returns null when prerequisite completed', () async {
    await tracker.markTrackCompleted('mtt_pro');
    final reason = await service.getUnlockReason('live_exploit');
    expect(reason, isNull);
  });
}
