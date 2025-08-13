import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/assessment_pack_synthesizer.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/pack_novelty_guard_service.dart';

class _FakeGuard extends PackNoveltyGuardService {
  int calls = 0;
  @override
  Future<PackNoveltyResult> evaluate(TrainingPackTemplateV2 candidate) async {
    calls++;
    return PackNoveltyResult(
      isDuplicate: calls == 1,
      jaccard: 1.0,
      overlapCount: 0,
      bestMatchId: null,
      topSimilar: const [],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deterministic id and novelty fallback', () async {
    final guard = _FakeGuard();
    final synth = AssessmentPackSynthesizer(noveltyGuard: guard);
    final pack = await synth.createAssessment(
      tags: const ['a', 'b'],
      size: 6,
      clusterId: 'c1',
      themeName: 'Theme',
    );
    expect(guard.calls, 2);
    expect(pack.spotCount, 4); // size reduced by 2 after duplicate
    final pack2 = await synth.createAssessment(
      tags: const ['a', 'b'],
      size: 6,
      clusterId: 'c1',
      themeName: 'Theme',
    );
    expect(pack.id, pack2.id); // deterministic
    expect(pack.meta['assessment'], true);
    expect(pack.meta['clusterId'], 'c1');
    expect(pack.meta['themeName'], 'Theme');
  });
}
