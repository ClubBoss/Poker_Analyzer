import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/autogen_pipeline_state_service.dart';
import 'package:poker_analyzer/widgets/autogen_pipeline_control_panel_widget.dart';

void main() {
  group('AutogenPipelineControlPanelWidget', () {
    setUp(() {
      AutogenPipelineStateService.getCurrentState().value =
          AutogenPipelineStatus.ready;
    });

    testWidgets('updates pipeline state and disables buttons accordingly',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AutogenPipelineControlPanelWidget()),
      ));

      final notifier = AutogenPipelineStateService.getCurrentState();

      // Start -> publishing
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(notifier.value, AutogenPipelineStatus.publishing);
      expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Start'))
            .onPressed,
        isNull,
      );

      // Reset -> ready
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(notifier.value, AutogenPipelineStatus.ready);
      expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Start'))
            .onPressed,
        isNotNull,
      );

      // Pause -> paused
      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(notifier.value, AutogenPipelineStatus.paused);
      expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Pause'))
            .onPressed,
        isNull,
      );
    });
  });
}

