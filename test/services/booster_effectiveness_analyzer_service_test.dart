import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/models/training_pack.dart';
import 'package:poker_analyzer/models/training_pack_template.dart';
import 'package:poker_analyzer/services/booster_effectiveness_analyzer_service.dart';
import 'package:poker_analyzer/services/booster_stats_tracker_service.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getLibraryPath() async => path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationCachePath() async => path;
  @override
  Future<String?> getExternalStoragePath() async => path;
  @override
  Future<List<String>?> getExternalCachePaths() async => [path];
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async =>
      [path];
  @override
  Future<String?> getDownloadsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computes average gains and top tags', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    await Hive.initFlutter();
    await Hive.openBox('booster_stats_box');

    final tracker = BoosterStatsTrackerService();
    final analyzer = BoosterEffectivenessAnalyzerService(tracker: tracker);

    final tpl1 = TrainingPackTemplate(
      id: 'b1',
      name: 'B1',
      gameType: 'g',
      description: '',
      hands: const [],
      tags: const ['tag1'],
    );
    final tpl2 = TrainingPackTemplate(
      id: 'b2',
      name: 'B2',
      gameType: 'g',
      description: '',
      hands: const [],
      tags: const ['tag2'],
    );
    final tpl3 = TrainingPackTemplate(
      id: 'b3',
      name: 'B3',
      gameType: 'g',
      description: '',
      hands: const [],
      tags: const ['tag3'],
    );

    // tag1 sessions: 0.5 -> 0.8 -> 0.9 (avg gain 0.2)
    await tracker.logBoosterResult(
      tpl1,
      TrainingSessionResult(date: DateTime(2024, 1, 1), total: 10, correct: 5),
    );
    await tracker.logBoosterResult(
      tpl1,
      TrainingSessionResult(date: DateTime(2024, 1, 2), total: 10, correct: 8),
    );
    await tracker.logBoosterResult(
      tpl1,
      TrainingSessionResult(date: DateTime(2024, 1, 3), total: 10, correct: 9),
    );

    // tag2 sessions: 0.7 -> 0.8 -> 0.8 (avg gain 0.05)
    await tracker.logBoosterResult(
      tpl2,
      TrainingSessionResult(date: DateTime(2024, 1, 1), total: 10, correct: 7),
    );
    await tracker.logBoosterResult(
      tpl2,
      TrainingSessionResult(date: DateTime(2024, 1, 2), total: 10, correct: 8),
    );
    await tracker.logBoosterResult(
      tpl2,
      TrainingSessionResult(date: DateTime(2024, 1, 3), total: 10, correct: 8),
    );

    // tag3 sessions: only two, should be excluded from top tags
    await tracker.logBoosterResult(
      tpl3,
      TrainingSessionResult(date: DateTime(2024, 1, 1), total: 10, correct: 4),
    );
    await tracker.logBoosterResult(
      tpl3,
      TrainingSessionResult(date: DateTime(2024, 1, 2), total: 10, correct: 6),
    );

    final gainTag1 = await analyzer.getAverageGain('tag1');
    expect(gainTag1, isNotNull);
    expect(gainTag1!, closeTo(0.2, 0.001));

    final top = await analyzer.getTopEffectiveTags();
    expect(top.keys.toList(), ['tag1', 'tag2']);
    expect(top['tag1'], closeTo(0.2, 0.001));
    expect(top['tag2'], closeTo(0.05, 0.001));
    expect(top.containsKey('tag3'), isFalse);
  });
}
