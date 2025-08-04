import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/recall_boost_interaction_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logs view events', () async {
    SharedPreferences.setMockInitialValues({});
    final logger = RecallBoostInteractionLogger.instance;
    logger.resetForTest();
    await logger.logView('push', 'node1', 1200);
    final logs = await logger.getLogs();
    expect(logs, hasLength(1));
    expect(logs.first.tag, 'push');
    expect(logs.first.nodeId, 'node1');
    expect(logs.first.durationMs, 1200);
  });
}
