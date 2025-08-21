import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/booster_mistake_recorder.dart';
import 'package:poker_analyzer/services/mistake_tag_history_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_action.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

TrainingPackTemplateV2 _tpl(TrainingPackSpot spot) => TrainingPackTemplateV2(
  id: 'b1',
  name: 'b1',
  trainingType: TrainingType.theory,
  tags: const ['cbet'],
  spots: [spot],
  spotCount: 1,
  created: DateTime.now(),
  gameType: GameType.tournament,
  positions: const [],
  meta: const {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records booster mistakes', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});

    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(
        position: HeroPosition.btn,
        heroIndex: 0,
        actions: {
          0: [
            ActionEntry(0, 0, 'push', ev: 1),
            ActionEntry(0, 0, 'fold', ev: 0),
          ],
        },
        stacks: const {'0': 10, '1': 10},
      ),
      correctAction: 'push',
      tags: const ['cbet'],
    );
    final booster = _tpl(spot);

    await BoosterMistakeRecorder.instance.load();
    await BoosterMistakeRecorder.instance.recordSession(
      booster: booster,
      actions: [
        TrainingAction(spotId: 's1', chosenAction: 'fold', isCorrect: false),
      ],
      spots: [spot],
    );

    final history = await MistakeTagHistoryService.getRecentHistory(limit: 10);
    expect(history.length, 1);
    expect(history.first.tags, contains(MistakeTag.overfoldBtn));
  });
}
