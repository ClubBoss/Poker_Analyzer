import 'dart:async';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/models/autogen_status.dart';

void main() {
  final service = AutogenStatusDashboardService.instance;

  setUp(() {
    service.clear();
  });

  tearDown(() {
    service.clear();
  });

  test('bindStream updates pipeline status', () async {
    final controller = StreamController<AutogenStatus>();
    await service.bindStream(controller.stream);
    controller.add(
      AutogenStatus(state: AutogenRunState.running, currentStep: 's1'),
    );
    await Future.delayed(const Duration(milliseconds: 10));
    expect(service.pipelineStatus.value.currentStep, 's1');
    await controller.close();
  });
}
