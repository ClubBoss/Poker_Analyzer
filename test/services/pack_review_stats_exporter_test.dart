import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:poker_analyzer/models/session_task_result.dart';
import 'package:poker_analyzer/models/training_pack.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/services/pack_review_stats_exporter.dart';

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

  test('exportSessionStats stores session statistics', () async {
    final dir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = _TestPathProvider(dir.path);

    final exporter = PackReviewStatsExporter();
    final template = TrainingPackTemplate(
      id: 'tpl1',
      name: 'Test Pack',
      spots: [
        TrainingPackSpot(id: 's1', tags: ['tagA']),
        TrainingPackSpot(id: 's2', tags: ['tagA', 'tagB']),
      ],
    );
    final result = TrainingSessionResult(
      date: DateTime(2024, 1, 1),
      total: 2,
      correct: 1,
      tasks: [
        SessionTaskResult(question: 's1', selectedAnswer: 'a', correctAnswer: 'a', correct: true),
        SessionTaskResult(question: 's2', selectedAnswer: 'a', correctAnswer: 'b', correct: false),
      ],
    );
    await exporter.exportSessionStats(template, result, const Duration(seconds: 30));

    final box = Hive.box('pack_review_stats_box');
    expect(box.length, 1);
    final data = Map<String, dynamic>.from(box.values.first);
    expect(data['templateId'], 'tpl1');
    expect(data['totalHands'], 2);
    expect(data['correctHands'], 1);
    expect(data['durationSeconds'], 30);
    final tags = Map<String, dynamic>.from(data['tagBreakdown']);
    final tagA = Map<String, dynamic>.from(tags['tagA']);
    expect(tagA['total'], 2);
    expect(tagA['correct'], 1);
    final tagB = Map<String, dynamic>.from(tags['tagB']);
    expect(tagB['total'], 1);
    expect(tagB['correct'], 0);
  });
}

