import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_stage_completion_watcher.dart';
import 'package:poker_analyzer/services/theory_stage_progress_tracker.dart';

class _TestWidget extends StatefulWidget {
  final ScrollController controller;
  final TheoryStageCompletionWatcher watcher;
  const _TestWidget({required this.controller, required this.watcher});

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> {
  @override
  void initState() {
    super.initState();
    widget.watcher.observe('stage1', widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListView.builder(
        controller: widget.controller,
        itemCount: 30,
        itemBuilder: (_, i) => SizedBox(height: 40, child: Text('Item \$i')),
      ),
    );
  }

  @override
  void dispose() {
    widget.watcher.dispose();
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('marks completed when scrolled to bottom', (tester) async {
    final controller = ScrollController();
    final watcher = TheoryStageCompletionWatcher(
      autoCompleteDelay: const Duration(seconds: 5),
    );
    await tester
        .pumpWidget(_TestWidget(controller: controller, watcher: watcher));
    await tester.pump();

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(await TheoryStageProgressTracker.instance.isCompleted('stage1'),
        isTrue);
  });

  testWidgets('marks completed after delay', (tester) async {
    final controller = ScrollController();
    final watcher = TheoryStageCompletionWatcher(
      autoCompleteDelay: const Duration(milliseconds: 500),
    );
    await tester
        .pumpWidget(_TestWidget(controller: controller, watcher: watcher));
    await tester.pump(const Duration(seconds: 1));

    expect(await TheoryStageProgressTracker.instance.isCompleted('stage1'),
        isTrue);
  });
}
