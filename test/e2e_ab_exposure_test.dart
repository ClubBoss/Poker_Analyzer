import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/autogen_pipeline_executor.dart';
import 'package:poker_analyzer/services/autogen_pipeline_event_logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'ab.enabled': true});
    AutogenPipelineEventLoggerService.clearLog();
  });

  test('exposure logged once per run', () async {
    final exec = AutogenPipelineExecutor();
    await exec.planAndInjectForUser('userExp', durationMinutes: 15);
    final log = AutogenPipelineEventLoggerService.getLog();
    final exposures = log.where((e) => e.type == 'ab_exposure').length;
    expect(exposures, 1);
  });
}
