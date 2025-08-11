import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/controllers/pack_run_controller.dart';
import 'package:poker_analyzer/models/pack_run_session_state.dart';
import 'package:poker_analyzer/models/theory_snippet.dart';
import 'package:poker_analyzer/services/learning_path_telemetry.dart';
import 'package:poker_analyzer/services/theory_index_service.dart';

class _FakeTheoryIndexService extends TheoryIndexService {
  @override
  Future<List<TheorySnippet>> snippetsForTag(String tag) async {
    return [const TheorySnippet(id: 's1', title: 't', bullets: [])];
  }
}

void main() {
  testWidgets('triggering recall logs without prints', (tester) async {
    final dir = await Directory.systemTemp.createTemp('telemetry');
    final telemetry = LearningPathTelemetry.test(dir: dir);
    final controller = PackRunController(
      packId: 'p1',
      sessionId: 's1',
      theoryIndex: _FakeTheoryIndexService(),
      state: PackRunSessionState(),
      telemetry: telemetry,
    );
    final prints = <String>[];
    await runZoned(() async {
      await controller.onResult('spot1', false, ['tag1']);
    }, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      prints.add(line);
    }));
    expect(prints, isEmpty);
  });
}
