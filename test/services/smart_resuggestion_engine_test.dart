import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/smart_resuggestion_engine.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> _list;
  _FakeLogService(this._list) : super(sessions: TrainingSessionService());

  @override
  Future<void> load() async {}

  @override
  List<SessionLog> get logs => List.unmodifiable(_list);
}

TrainingPackTemplateV2 _tpl(String id) => TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.pushFold,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns pack with highest engagement', () async {
    final old =
        DateTime.now().subtract(const Duration(days: 20)).toIso8601String();
    SharedPreferences.setMockInitialValues({
      'suggested_pack_history': jsonEncode([
        {'id': 'a', 'source': 't', 'ts': old},
        {'id': 'a', 'source': 't', 'ts': old},
        {'id': 'b', 'source': 't', 'ts': old},
      ])
    });

    final engine = SmartReSuggestionEngine(
      logs: _FakeLogService([]),
      library: [_tpl('a'), _tpl('b')],
    );
    final pack = await engine.suggestNext();
    expect(pack?.id, 'a');
  });

  test('respects cooldown window', () async {
    final recent =
        DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
    SharedPreferences.setMockInitialValues({
      'suggested_pack_history': jsonEncode([
        {'id': 'a', 'source': 't', 'ts': recent},
        {'id': 'a', 'source': 't', 'ts': recent},
      ])
    });

    final engine = SmartReSuggestionEngine(
      logs: _FakeLogService([]),
      library: [_tpl('a')],
    );
    final pack = await engine.suggestNext();
    expect(pack, isNull);
  });
}
