import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_inbox_feedback_logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logs events and retrieves summary', () async {
    final logger = SmartInboxFeedbackLoggerService.instance;

    await logger.logEvent('booster_tag_preflop_bb_vs_btn', 'viewed');
    await logger.logEvent('booster_tag_preflop_bb_vs_btn', 'clicked');
    await logger.logEvent('theory_reminder_xyz', 'dismissed');

    final summary = await logger.getFeedbackSummary();

    expect(
      summary['booster_tag_preflop_bb_vs_btn']?.containsKey('viewed'),
      isTrue,
    );
    expect(
      summary['booster_tag_preflop_bb_vs_btn']?.containsKey('clicked'),
      isTrue,
    );
    expect(summary['theory_reminder_xyz']?.containsKey('dismissed'), isTrue);
  });
}
