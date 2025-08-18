import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/auto_format_selector.dart';
import 'package:poker_analyzer/services/training_pack_auto_generator.dart';
import 'package:poker_analyzer/services/autogen_pipeline_event_logger_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AutogenPipelineEventLoggerService.clearLog();
  });

  test('applyTo sets generator parameters', () async {
    SharedPreferences.setMockInitialValues({
      'ab.recommended_format': jsonEncode({
        'spotsPerPack': 15,
        'streets': 2,
        'theoryRatio': 0.7,
      }),
    });
    final selector = AutoFormatSelector();
    await selector.load();
    final gen = TrainingPackAutoGenerator();
    selector.applyTo(gen);
    expect(gen.spotsPerPack, 15);
    expect(gen.streets, 2);
    expect(gen.theoryRatio, 0.7);
  });

  test('audience override takes precedence', () async {
    SharedPreferences.setMockInitialValues({
      'ab.recommended_format': jsonEncode({
        'spotsPerPack': 10,
        'streets': 1,
        'theoryRatio': 0.5,
      }),
      'ab.overrides.pro': jsonEncode({
        'spotsPerPack': 20,
        'streets': 3,
        'theoryRatio': 0.8,
      }),
    });
    final selector = AutoFormatSelector();
    await selector.load();
    final fmt = selector.effectiveFormat(audience: 'pro');
    expect(fmt.spotsPerPack, 20);
    expect(fmt.streets, 3);
    expect(fmt.theoryRatio, 0.8);
  });

  test('fallback logs notice when no winner', () async {
    final selector = AutoFormatSelector();
    await selector.load();
    final gen = TrainingPackAutoGenerator();
    selector.applyTo(gen);
    final log = AutogenPipelineEventLoggerService.getLog();
    expect(log.any((e) => e.message.contains('fallback')), isTrue);
  });
}
