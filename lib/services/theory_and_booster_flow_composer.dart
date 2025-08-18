import 'booster_injection_orchestrator.dart';
import 'injection_block_assembler.dart';
import 'smart_theory_injection_engine.dart';
import '../models/learning_path_block.dart';
import 'path_map_engine.dart';

/// Builds the adaptive flow of a stage combining theory and booster injections.
class TheoryAndBoosterFlowComposer {
  final SmartTheoryInjectionEngine theoryEngine;
  final BoosterInjectionOrchestrator boosterOrchestrator;
  final InjectionBlockAssembler assembler;

  const TheoryAndBoosterFlowComposer({
    SmartTheoryInjectionEngine? theoryEngine,
    required BoosterInjectionOrchestrator boosterOrchestrator,
    InjectionBlockAssembler? assembler,
  }) : theoryEngine = theoryEngine ?? const SmartTheoryInjectionEngine(),
       boosterOrchestrator = boosterOrchestrator,
       assembler = assembler ?? const InjectionBlockAssembler();

  /// Returns ordered blocks for [stage] with theory first and boosters after.
  Future<List<LearningPathBlock>> buildStageFlow(StageNode stage) async {
    final result = <LearningPathBlock>[];
    final miniLesson = await theoryEngine.getInjectionCandidate(stage.id);
    if (miniLesson != null) {
      result.add(assembler.build(miniLesson, stage.id));
    }
    final boosters = await boosterOrchestrator.getInjectableBoosters(stage);
    if (boosters.isNotEmpty) {
      result.addAll(boosters.take(2));
    }
    return result;
  }
}
