import 'dart:io';

import 'package:poker_analyzer/services/deduplication_policy_engine.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrainingPackTemplateV2 _pack(String id, List<TrainingPackSpot> spots) =>
    TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );

TrainingPackSpot _spot(String id, String cards) => TrainingPackSpot(
      id: id,
      hand: HandData.fromSimpleInput(cards, HeroPosition.btn, 10),
    );

void main() {
  late Directory dir;
  late DeduplicationPolicyEngine engine;
  final status = AutogenStatusDashboardService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    status.clear();
    dir = await Directory.systemTemp.createTemp('dedup_test');
    engine = DeduplicationPolicyEngine(status: status, outputDir: dir.path);
  });

  tearDown(() async {
    await dir.delete(recursive: true);
    status.clear();
  });

  test('merge action combines packs and updates dashboard', () async {
    await engine.setPolicies([
      const DeduplicationPolicy(
        reason: 'duplicate',
        action: DeduplicationAction.merge,
        threshold: 0.9,
      ),
    ]);

    final existing = _pack('existing', [_spot('a', 'AhAs')]);
    final candidate = _pack('candidate', [
      _spot('b', 'AhAs'),
      _spot('c', 'KdQc'),
    ]);
    await File(
      '${dir.path}/existing.yaml',
    ).writeAsString(existing.toYamlString());
    await File(
      '${dir.path}/candidate.yaml',
    ).writeAsString(candidate.toYamlString());

    final d = DuplicatePackInfo(
      candidateId: 'candidate',
      existingId: 'existing',
      similarity: 1.0,
      reason: 'duplicate',
    );

    await engine.applyPolicies([d]);

    expect(File('${dir.path}/candidate.yaml').existsSync(), isFalse);
    final merged = TrainingPackTemplateV2.fromYaml(
      await File('${dir.path}/existing.yaml').readAsString(),
    );
    expect(merged.spots, hasLength(2));
    expect(merged.spotCount, 2);
    expect(merged.meta['mergedIds'], contains('candidate'));
    final info = status.duplicates.first;
    expect(info.reason, 'merged by policy');
    expect(info.candidateId, 'candidate');
    expect(info.existingId, 'existing');
  });

  test('rename action assigns new id and updates dashboard', () async {
    await engine.setPolicies([
      const DeduplicationPolicy(
        reason: 'duplicate',
        action: DeduplicationAction.rename,
        threshold: 0.9,
      ),
    ]);

    final existing = _pack('existing', [_spot('a', 'AhAs')]);
    final candidate = _pack('candidate', [_spot('b', 'KdQc')]);
    await File(
      '${dir.path}/existing.yaml',
    ).writeAsString(existing.toYamlString());
    await File(
      '${dir.path}/candidate.yaml',
    ).writeAsString(candidate.toYamlString());

    final d = DuplicatePackInfo(
      candidateId: 'candidate',
      existingId: 'existing',
      similarity: 1.0,
      reason: 'duplicate',
    );

    await engine.applyPolicies([d]);

    expect(File('${dir.path}/candidate.yaml').existsSync(), isFalse);
    final newFile = File('${dir.path}/candidate_v2.yaml');
    expect(newFile.existsSync(), isTrue);
    final renamed = TrainingPackTemplateV2.fromYaml(
      await newFile.readAsString(),
    );
    expect(renamed.id, 'candidate_v2');
    expect(renamed.meta['renamedFrom'], 'candidate');
    final info = status.duplicates.first;
    expect(info.reason, 'renamed by policy');
    expect(info.candidateId, 'candidate_v2');
    expect(info.existingId, 'existing');
  });
}
