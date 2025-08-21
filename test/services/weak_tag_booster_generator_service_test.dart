import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/tag_weakness_detector_service.dart';
import 'package:poker_analyzer/services/weak_tag_booster_generator_service.dart';
import 'package:poker_analyzer/repositories/training_pack_repository.dart';

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

class _FakeRepo extends TrainingPackRepository {
  final Map<String, List<TrainingPackSpot>> _map;
  const _FakeRepo(this._map);

  @override
  Future<List<TrainingPackSpot>> getSpotsByTag(String tag) async =>
      _map[tag] ?? [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generateWeakTagBooster builds pack from weakest tags', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    await Hive.initFlutter();
    final box = await Hive.openBox('pack_review_stats_box');
    await box.add({
      'tagBreakdown': {
        'A': {'total': 3, 'correct': 1},
      },
    });
    await box.add({
      'tagBreakdown': {
        'B': {'total': 3, 'correct': 1},
      },
    });

    final repo = _FakeRepo({
      'A': [
        for (var i = 0; i < 5; i++) TrainingPackSpot(id: 'A$i', tags: ['A']),
      ],
      'B': [
        for (var i = 0; i < 5; i++) TrainingPackSpot(id: 'B$i', tags: ['B']),
      ],
    });

    final service = WeakTagBoosterGeneratorService(
      weaknessDetector: TagWeaknessDetectorService(),
      spotLibrary: repo,
      random: Random(1),
    );

    final tpl = await service.generateWeakTagBooster();

    expect(tpl.name, 'Weak Tag Booster');
    expect(tpl.trainingType, TrainingType.booster);
    expect(tpl.meta['type'], 'booster');
    expect(tpl.tags, ['A', 'B']);
    expect(tpl.spots.length, inInclusiveRange(6, 10));
    for (final tag in tpl.tags) {
      final count = tpl.spots.where((s) => s.tags.contains(tag)).length;
      expect(count, greaterThan(0));
    }
  });
}
