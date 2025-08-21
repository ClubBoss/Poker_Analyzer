import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/tag_retention_tracker.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class FakeTagMasteryService extends TagMasteryService {
  final Map<String, double> _mastery;
  final Map<String, DateTime> _last;
  final Map<String, double> _acc;
  FakeTagMasteryService(this._mastery, this._last, this._acc)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _mastery;

  @override
  Future<Map<String, DateTime>> getLastTrained() async => _last;

  @override
  Future<Map<String, double>> getLastAccuracy() async => _acc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects decayed tags', () async {
    final now = DateTime(2024, 1, 10);
    final mastery = FakeTagMasteryService(
      {'push': 0.9, 'call': 0.8},
      {
        'push': now.subtract(const Duration(days: 10)),
        'call': now.subtract(const Duration(days: 1)),
      },
      {'push': 0.9, 'call': 0.95},
    );
    final tracker = TagRetentionTracker(mastery: mastery);
    final decayed = await tracker.getDecayedTags(now: now);
    expect(decayed, contains('push'));
    expect(decayed, isNot(contains('call')));
  });
}
