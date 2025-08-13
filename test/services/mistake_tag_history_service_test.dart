import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/mistake_tag_history_service.dart';
import 'package:poker_analyzer/services/tag_mastery_trend_service.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

TrainingSpotAttempt _attempt(String spotId, {double ev = -1}) {
  final spot = TrainingPackSpot(id: spotId, hand: HandData());
  return TrainingSpotAttempt(
    spot: spot,
    userAction: 'fold',
    correctAction: 'push',
    evDiff: ev,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logTags stores and retrieves history', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);

    await MistakeTagHistoryService.logTags(
      'p1',
      _attempt('s1'),
      [MistakeTag.overfoldBtn],
    );
    await MistakeTagHistoryService.logTags(
      'p1',
      _attempt('s2'),
      [MistakeTag.overfoldBtn, MistakeTag.missedEvPush],
    );

    final freq = await MistakeTagHistoryService.getTagsByFrequency();
    expect(freq[MistakeTag.overfoldBtn], 2);
    expect(freq[MistakeTag.missedEvPush], 1);

    final recent = await MistakeTagHistoryService.getRecentMistakesByTag(
        MistakeTag.overfoldBtn);
    expect(recent.length, 2);
    expect(recent.first.spotId, 's2');
  });

  test('getTrend detects rising trend', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _FakePathProvider(dir.path);

    final now = DateTime.now();
    for (int i = 0; i < 14; i++) {
      final ts = now.subtract(Duration(days: 13 - i));
      final spot = TrainingPackSpot(id: 's$i', hand: HandData());
      final attempt = TrainingSpotAttempt(
        spot: spot,
        userAction: 'fold',
        correctAction: 'push',
        evDiff: -1,
      );
      await MistakeTagHistoryService.logTags(
        'p1',
        attempt,
        [MistakeTag.overfoldBtn],
      );
      final file = File('${dir.path}/app_data/mistake_tag_history.json');
      final data = await file.readAsString();
      final list = List<Map<String, dynamic>>.from(jsonDecode(data) as List);
      list[0]['timestamp'] = ts.toIso8601String();
      await file.writeAsString(jsonEncode(list), flush: true);
    }

    final trend =
        await MistakeTagHistoryService.getTrend(MistakeTag.overfoldBtn);
    expect(trend, TagTrend.rising);
  });
}
