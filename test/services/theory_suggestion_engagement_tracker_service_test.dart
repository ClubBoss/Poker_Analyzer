import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_suggestion_engagement_tracker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks lesson suggestion interactions', () async {
    final service = TheorySuggestionEngagementTrackerService.instance;

    await service.lessonSuggested('l1');
    await service.lessonExpanded('l1');
    await service.lessonOpened('l1');
    await service.lessonSuggested('l2');

    final suggested = await service.countByAction('suggested');
    final expanded = await service.countByAction('expanded');
    final opened = await service.countByAction('opened');

    expect(suggested['l1'], 1);
    expect(suggested['l2'], 1);
    expect(expanded['l1'], 1);
    expect(expanded['l2'], isNull);
    expect(opened['l1'], 1);
  });
}
