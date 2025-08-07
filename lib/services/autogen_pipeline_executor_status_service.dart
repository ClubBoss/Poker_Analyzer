import 'package:flutter/foundation.dart';

import 'autogen_pipeline_executor.dart';
import 'training_pack_auto_generator.dart';
import 'training_pack_template_set_library_service.dart';

/// Service exposing start/stop controls and running status for the
/// [AutogenPipelineExecutor].
class AutogenPipelineExecutorStatusService {
  AutogenPipelineExecutorStatusService._();

  static final AutogenPipelineExecutorStatusService _instance =
      AutogenPipelineExecutorStatusService._();

  factory AutogenPipelineExecutorStatusService() => _instance;
  static AutogenPipelineExecutorStatusService get instance => _instance;

  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  TrainingPackAutoGenerator? _generator;

  /// Starts the autogen pipeline.
  Future<void> startAutogen() async {
    if (isRunning.value) return;
    isRunning.value = true;
    final library = TrainingPackTemplateSetLibraryService.instance;
    await library.loadAll();
    final sets = library.all;
    final generator = TrainingPackAutoGenerator();
    _generator = generator;
    final executor = AutogenPipelineExecutor(generator: generator);
    try {
      await executor.execute(sets, existingYamlPath: 'packs/generated');
    } finally {
      isRunning.value = false;
    }
  }

  /// Aborts the pipeline if running.
  void stopAutogen() {
    _generator?.abort();
    isRunning.value = false;
  }
}
