import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/yaml_pack_exporter.dart';

class _FakeDecayTracker implements SkillDecayTracker {
  final List<String> tags;
  _FakeDecayTracker(this.tags);
  @override
  Future<List<String>> getDecayedTags({required double threshold}) async => tags;
  @override
  Stream<String> get onDecayStateChanged => const Stream.empty();
}

class _FakeMasteryAnalyzer implements TagMasteryAnalyzer {
  final List<String> tags;
  _FakeMasteryAnalyzer(this.tags);
  @override
  Future<List<String>> findWeakTags(double threshold) async => tags;
}

class _CapturingExporter extends YamlPackExporter {
  TrainingPackTemplateV2? last;
  @override
  Future<File> export(TrainingPackTemplateV2 pack) async {
    last = pack;
    final file = File('${Directory.systemTemp.path}/test.yaml');
    await file.writeAsString('');
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TrainingPackLibraryV2.instance.clear();
    AutogenStatusDashboardService.instance.clear();
    final dir = Directory('boosterPacks');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  TrainingPackTemplateV2 buildPack(String id, String tag) {
    final spot1 =
        TrainingPackSpot(id: '${id}_s1', tags: [tag], board: ['As', 'Kd', '2c']);
    final spot2 =
        TrainingPackSpot(id: '${id}_s2', tags: [tag], board: ['Ah', 'Ks', '3d']);
    return TrainingPackTemplateV2(
      id: id,
      name: 'Sample $id',
      trainingType: TrainingType.custom,
      spots: [spot1, spot2],
      spotCount: 2,
      tags: [tag],
      gameType: GameType.cash,
    );
  }

  test('detects boost candidates from analytics', () async {
    final pack = buildPack('p1', 'push');
    TrainingPackLibraryV2.instance.addPack(pack);
    SharedPreferences.setMockInitialValues({
      'booster.threshold': 0.8,
      'booster.ratio': 2.0,
    });
    final engine = TargetedPackBoosterEngine(
      decayTracker: _FakeDecayTracker(['push']),
      masteryAnalyzer: _FakeMasteryAnalyzer(['push']),
    );
    final candidates = await engine.detectBoostCandidates();
    expect(candidates.length, 1);
    expect(candidates.first.packId, 'p1');
    expect(candidates.first.ratio, 2.0);
    expect(candidates.first.triggerReason, 'decayThreshold');
  });

  test('boostPacks exports boosted template', () async {
    final pack = buildPack('p2', 'fold');
    TrainingPackLibraryV2.instance.addPack(pack);
    final exporter = _CapturingExporter();
    final engine = TargetedPackBoosterEngine(exporter: exporter);
    final req = PackBoosterRequest(
      packId: 'p2',
      tags: ['fold'],
      ratio: 1.5,
      triggerReason: 'manual',
    );
    final result = await engine.boostPacks([req]);
    final boosted = result.single;
    expect(boosted.id, startsWith('p2_boosted_'));
    expect(boosted.spotCount, greaterThan(pack.spotCount));
    expect(boosted.meta['tagsTargeted'], ['fold']);
    expect(boosted.meta['triggerReason'], 'manual');
    expect(boosted.meta['type'], 'booster');
    for (final s in boosted.spots) {
      expect(s.tags, contains('fold'));
    }
    final dir = Directory('boosterPacks');
    expect(dir.existsSync(), isTrue);
    expect(dir.listSync().isNotEmpty, isTrue);
    final status = AutogenStatusDashboardService.instance;
    expect(status.boostersGeneratedNotifier.value, 1);
  });

  test('boostPacks skips duplicate packs', () async {
    final pack = buildPack('p3', 'fold');
    TrainingPackLibraryV2.instance.addPack(pack);
    final exporter = _CapturingExporter();
    final engine = TargetedPackBoosterEngine(exporter: exporter);
    final req = PackBoosterRequest(
      packId: 'p3',
      tags: ['fold'],
      ratio: 1.5,
      triggerReason: 'manual',
    );
    final result = await engine.boostPacks([req]);
    expect(result, isEmpty);
    final status = AutogenStatusDashboardService.instance;
    expect(status.boostersSkippedNotifier.value['duplicate'], 1);
  });

  class _StreamDecayTracker implements SkillDecayTracker {
    final StreamController<String> controller = StreamController.broadcast();
    final Set<String> decayed = {};
    int calls = 0;
    void emit(String tag) {
      decayed.add(tag);
      controller.add(tag);
    }

    @override
    Future<List<String>> getDecayedTags({required double threshold}) async {
      calls++;
      return decayed.toList();
    }

    @override
    Stream<String> get onDecayStateChanged => controller.stream;
  }

  test('auto-generates boosters when decay threshold crossed', () async {
    final pack = buildPack('p4', 'push');
    TrainingPackLibraryV2.instance.addPack(pack);
    final exporter = _CapturingExporter();
    final tracker = _StreamDecayTracker();
    final engine = TargetedPackBoosterEngine(
      exporter: exporter,
      decayTracker: tracker,
      decayDebounce: const Duration(milliseconds: 20),
    );
    tracker.emit('push');
    await Future.delayed(const Duration(milliseconds: 80));
    expect(exporter.last, isNotNull);
    expect(exporter.last!.meta['triggerReason'], 'decaySync');
  });

  test('decay events are batched into single generation pass', () async {
    final packA = buildPack('p5', 'a');
    final packB = buildPack('p6', 'b');
    TrainingPackLibraryV2.instance.addPack(packA);
    TrainingPackLibraryV2.instance.addPack(packB);
    final tracker = _StreamDecayTracker();
    final engine = TargetedPackBoosterEngine(
      decayTracker: tracker,
      decayDebounce: const Duration(milliseconds: 20),
    );
    tracker.emit('a');
    tracker.emit('b');
    await Future.delayed(const Duration(milliseconds: 80));
    final status = AutogenStatusDashboardService.instance;
    expect(status.boostersGeneratedNotifier.value, 2);
    expect(tracker.calls, 1);
  });

  test('skips generating booster if recent duplicate exists', () async {
    final pack = buildPack('p7', 'c');
    TrainingPackLibraryV2.instance.addPack(pack);
    final dir = Directory('boosterPacks');
    await dir.create(recursive: true);
    final existing = TrainingPackTemplateV2(
      id: 'existing',
      name: 'existing',
      trainingType: TrainingType.custom,
      spots: pack.spots,
      spotCount: pack.spotCount,
      tags: ['c'],
      gameType: GameType.cash,
      meta: {
        'type': 'booster',
        'tagsTargeted': ['c'],
        'generatedAt': DateTime.now().toIso8601String(),
      },
    );
    final file = File('${dir.path}/existing.yaml');
    await file.writeAsString(existing.toYamlString());

    final tracker = _StreamDecayTracker();
    final exporter = _CapturingExporter();
    final engine = TargetedPackBoosterEngine(
      exporter: exporter,
      decayTracker: tracker,
      decayDebounce: const Duration(milliseconds: 20),
    );
    tracker.emit('c');
    await Future.delayed(const Duration(milliseconds: 80));
    final status = AutogenStatusDashboardService.instance;
    expect(status.boostersGeneratedNotifier.value, 0);
    expect(status.boostersSkippedNotifier.value['recent_duplicate'], 1);
  });
}
