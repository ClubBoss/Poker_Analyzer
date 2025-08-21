import 'package:flutter/widgets.dart';

import '../services/mini_lesson_library_service.dart';
import '../services/theory_and_booster_flow_composer.dart';
import '../services/booster_injection_orchestrator.dart';
import '../services/tag_mastery_service.dart';
import '../services/booster_inventory_service.dart';
import '../services/session_log_service.dart';
import '../services/training_session_service.dart';
import '../services/training_session_launcher.dart';
import 'path_map_engine.dart';
import '../widgets/injected_theory_block_renderer.dart';
import '../widgets/drill_preview_block.dart';

/// Injects theory and booster blocks into the stage UI.
class StageFlowInjectionRunner {
  final TheoryAndBoosterFlowComposer composer;
  final MiniLessonLibraryService miniLessons;
  final BoosterInventoryService boosters;
  final TrainingSessionLauncher launcher;

  StageFlowInjectionRunner({
    TheoryAndBoosterFlowComposer? composer,
    MiniLessonLibraryService? miniLessons,
    BoosterInventoryService? boosters,
    TrainingSessionLauncher launcher = const TrainingSessionLauncher(),
  })  : composer = composer ??
            TheoryAndBoosterFlowComposer(
              boosterOrchestrator: BoosterInjectionOrchestrator(
                mastery: TagMasteryService(
                  logs: SessionLogService(sessions: TrainingSessionService()),
                ),
                inventory: boosters ?? BoosterInventoryService(),
              ),
            ),
        miniLessons = miniLessons ?? MiniLessonLibraryService.instance,
        boosters = boosters ?? BoosterInventoryService(),
        launcher = launcher;

  /// Returns widgets to inject for [stage].
  Future<List<Widget>> injectBlocks(StageNode stage) async {
    final blocks = await composer.buildStageFlow(stage);
    if (blocks.isEmpty) return [];
    await miniLessons.loadAll();
    await boosters.loadAll();
    final widgets = <Widget>[];
    for (final block in blocks) {
      final lesson = miniLessons.getById(block.lessonId);
      if (lesson != null) {
        widgets.add(InjectedTheoryBlockRenderer(block: block));
      } else {
        widgets.add(
          DrillPreviewBlock(
            block: block,
            inventory: boosters,
            launcher: launcher,
          ),
        );
      }
    }
    return widgets;
  }
}
