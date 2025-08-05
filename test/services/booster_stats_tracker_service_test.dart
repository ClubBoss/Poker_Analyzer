import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/models/training_pack.dart';
import 'package:poker_analyzer/models/training_pack_template.dart';
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
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [path];
  @override
  Future<String?> getDownloadsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logs and retrieves booster progress', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);
    await Hive.initFlutter();
    await Hive.openBox('booster_stats_box');

    final service = BoosterStatsTrackerService();
    final tpl = TrainingPackTemplate(
      id: 'b1',
      name: 'B',
      gameType: 'game',
      description: '',
      hands: const [],
      tags: const ['tag1'],
    );
    final r1 = TrainingSessionResult(date: DateTime(2024, 1, 1), total: 10, correct: 5);
    final r2 = TrainingSessionResult(date: DateTime(2024, 1, 2), total: 10, correct: 8);

    await service.logBoosterResult(tpl, r1);
    await service.logBoosterResult(tpl, r2);

    final progress = await service.getProgressForTag('tag1');
    expect(progress.length, 2);
    expect(progress[0].accuracy, closeTo(0.5, 0.001));
    expect(progress[1].accuracy, closeTo(0.8, 0.001));
    expect(progress[0].date, r1.date);
    expect(progress[1].date, r2.date);
  });
}

