import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/app_config.dart';
import 'package:poker_analyzer/services/smart_path_ux_hints_service.dart';

void main() {
  const service = SmartPathUXHintsService();

  test('hint after pack completion', () async {
    appConfig.showSmartPathHints = true;
    const ctx = LearningContext(
      stageTitle: 'Stage 1',
      stageProgress: 0.85,
      afterPackCompleted: true,
    );
    final hint = await service.getHint(ctx);
    expect(hint, contains('почти закрыл'));
  });

  test('hint for frequent errors', () async {
    const ctx = LearningContext(
      stageTitle: 'Stage 1',
      stageProgress: 0.2,
      errorCounts: {'BB': 4},
    );
    final hint = await service.getHint(ctx);
    expect(hint, contains('позиции BB'));
  });

  test('hint for stagnation', () async {
    const ctx = LearningContext(
      stageTitle: 'Stage 1',
      stageProgress: 0.5,
      recentEv: [-1, -0.5, -0.2],
    );
    final hint = await service.getHint(ctx);
    expect(hint, contains('Застопорился'));
  });

  test('no hint when disabled', () async {
    appConfig.showSmartPathHints = false;
    const ctx = LearningContext(stageTitle: 'Stage', stageProgress: 0.9);
    final hint = await service.getHint(ctx);
    expect(hint, isNull);
    appConfig.showSmartPathHints = true;
  });
}
