import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/services/tag_weakness_detector_service.dart';

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

  test('getWeakTags returns underperforming tags', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    await Hive.initFlutter();
    final box = await Hive.openBox('pack_review_stats_box');

    await box.add({
      'tagBreakdown': {
        'A': {'total': 1, 'correct': 0},
        'B': {'total': 1, 'correct': 0},
        'D': {'total': 1, 'correct': 1},
      },
    });
    await box.add({
      'tagBreakdown': {
        'A': {'total': 1, 'correct': 0},
        'D': {'total': 1, 'correct': 1},
      },
    });
    await box.add({
      'tagBreakdown': {
        'A': {'total': 1, 'correct': 1},
        'D': {'total': 1, 'correct': 0},
      },
    });

    final service = TagWeaknessDetectorService();
    final weak = await service.getWeakTags();
    expect(weak, ['A', 'D']);
  });

  test('getWeakTags respects maxSessions', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    await Hive.initFlutter();
    final box = await Hive.openBox('pack_review_stats_box');

    await box.add({
      'tagBreakdown': {
        'A': {'total': 1, 'correct': 0},
      },
    });
    await box.add({
      'tagBreakdown': {
        'A': {'total': 1, 'correct': 0},
      },
    });
    await box.add({
      'tagBreakdown': {
        'A': {'total': 1, 'correct': 1},
      },
    });

    final service = TagWeaknessDetectorService();
    final weak = await service.getWeakTags(maxSessions: 2);
    expect(weak, isEmpty);
  });
}
