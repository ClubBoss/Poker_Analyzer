import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/stage_type.dart';
import '../models/theory_pack_model.dart';
import '../services/theory_pack_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../screens/theory_pack_reader_screen.dart';
import 'user_action_logger.dart';
import 'overlay_decay_booster_orchestrator.dart';
import 'dart:async';
import '../utils/snackbar_util.dart';

/// Helper to open a learning path stage.
class LearningPathStageLauncher {
  final PackLibraryService _library;
  final TheoryPackLibraryService _theoryLibrary;
  final TrainingSessionLauncher _launcher;

  const LearningPathStageLauncher({
    PackLibraryService? library,
    TheoryPackLibraryService? theoryLibrary,
    TrainingSessionLauncher launcher = const TrainingSessionLauncher(),
  })  : _library = library ?? PackLibraryService.instance,
        _theoryLibrary = theoryLibrary ?? TheoryPackLibraryService.instance,
        _launcher = launcher;

  Future<void> launch(BuildContext context, LearningPathStageModel stage) async {
    await UserActionLogger.instance.logEvent({
      'event': 'stage_opened',
      'type': stage.type.name,
      'id': stage.id,
      if (stage.tags.isNotEmpty) 'tags': stage.tags,
      'timestamp': DateTime.now().toIso8601String(),
    });

    unawaited(OverlayDecayBoosterOrchestrator.instance.maybeShow(context));

    switch (stage.type) {
      case StageType.theory:
        final id = stage.theoryPackId;
        if (id == null) {
          SnackbarUtil.showMessage(context, 'Theory pack not found');
          return;
        }
        await _theoryLibrary.loadAll();
        final pack = _theoryLibrary.getById(id);
        if (pack == null) {
          SnackbarUtil.showMessage(context, 'Theory pack not found');
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: TheoryPackReaderScreen.route),
            builder: (_) => TheoryPackReaderScreen(pack: pack, stageId: stage.id),
          ),
        );
        break;
      case StageType.practice:
        final tpl = await _library.getById(stage.packId);
        if (tpl == null) {
          SnackbarUtil.showMessage(context, 'Training pack not found');
          return;
        }
        await _launcher.launch(tpl);
        break;
      case StageType.booster:
        TheoryPackModel? booster;
        await _theoryLibrary.loadAll();
        if (stage.boosterTheoryPackIds != null &&
            stage.boosterTheoryPackIds!.isNotEmpty) {
          booster = _theoryLibrary.getById(stage.boosterTheoryPackIds!.first);
        }
        booster ??= _theoryLibrary.all.firstWhereOrNull(
          (p) => stage.tags.any((t) => p.tags.contains(t)),
        );
        if (booster == null) {
          SnackbarUtil.showMessage(context, 'Booster not found');
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: TheoryPackReaderScreen.route),
            builder: (_) => TheoryPackReaderScreen(pack: booster!, stageId: stage.id),
          ),
        );
        break;
    }
  }
}
