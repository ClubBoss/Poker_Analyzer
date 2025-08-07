import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/training/engine/training_type_engine.dart';
import '../models/autogen_step_status.dart';
import '../models/game_type.dart';
import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/autogen_pipeline_debug_stats_service.dart';
import '../services/autogen_pipeline_event_logger_service.dart';
import '../services/autogen_pipeline_executor.dart';
import '../services/autogen_pipeline_session_tracker_service.dart';
import '../services/training_pack_auto_generator.dart';
import '../services/training_pack_template_set_library_service.dart';
import '../services/yaml_pack_exporter.dart';

class AutogenPipelineDebugControlPanel extends StatefulWidget {
  const AutogenPipelineDebugControlPanel({super.key});

  @override
  State<AutogenPipelineDebugControlPanel> createState() =>
      _AutogenPipelineDebugControlPanelState();
}

class _AutogenPipelineDebugControlPanelState
    extends State<AutogenPipelineDebugControlPanel> {
  final TrainingPackAutoGenerator _generator = TrainingPackAutoGenerator();
  final YamlPackExporter _exporter = const YamlPackExporter();
  final AutogenPipelineSessionTrackerService _tracker =
      AutogenPipelineSessionTrackerService.instance;
  List<TrainingPackTemplateSet> _sets = [];
  TrainingPackTemplateSet? _selectedSet;
  TrainingPackTemplateV2? _pack;
  late final String _sessionId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sessionId = 'debug-${DateTime.now().millisecondsSinceEpoch}';
    TrainingPackTemplateSetLibraryService.instance.loadAll().then((_) {
      final all = TrainingPackTemplateSetLibraryService.instance.all;
      if (mounted) {
        setState(() {
          _sets = all;
          if (all.isNotEmpty) {
            _selectedSet = all.first;
          }
        });
      }
    });
  }

  Future<void> _guard(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _failStep(String name, Object e) {
    _tracker.updateStep(
      _sessionId,
      AutoGenStepStatus(
        stepName: name,
        status: 'error',
        errorMessage: e.toString(),
      ),
    );
    _showSnack('Error in $name: $e');
  }

  Future<void> _runGenerator() async {
    final set = _selectedSet;
    if (set == null) {
      _showSnack('Select a template set first');
      return;
    }
    _tracker.updateStep(
      _sessionId,
      const AutoGenStepStatus(stepName: 'Generator', status: 'running'),
    );
    try {
      final spots = await _generator.generate(set);
      if (spots.isEmpty) {
        _showSnack('No spots generated for ${set.baseSpot.id}');
        _tracker.updateStep(
          _sessionId,
          AutoGenStepStatus(
            stepName: 'Generator',
            status: 'error',
            errorMessage: 'No spots generated for ${set.baseSpot.id}',
          ),
        );
        return;
      }
      final base = set.baseSpot;
      final pack = TrainingPackTemplateV2(
        id: base.id,
        name: base.title.isNotEmpty ? base.title : base.id,
        trainingType: TrainingType.custom,
        spots: spots,
        spotCount: spots.length,
        tags: List<String>.from(base.tags),
        gameType: GameType.cash,
        bb: base.hand.stacks['0']?.toInt() ?? 0,
        positions: [base.hand.position.name],
        meta: Map<String, dynamic>.from(base.meta),
      );
      setState(() => _pack = pack);
      AutogenPipelineDebugStatsService.incrementGenerated();
      AutogenPipelineEventLoggerService.log(
        'generated',
        'Generated ${spots.length} spots for template ${set.baseSpot.id}',
      );
      _tracker.updateStep(
        _sessionId,
        const AutoGenStepStatus(stepName: 'Generator', status: 'ok'),
      );
      _showSnack('Generated ${spots.length} spots for ${set.baseSpot.id}');
    } catch (e) {
      _failStep('Generator', e);
    }
  }

  Future<void> _runEnricher() async {
    final pack = _pack;
    if (pack == null) {
      _showSnack('Run generator first');
      return;
    }
    _tracker.updateStep(
      _sessionId,
      const AutoGenStepStatus(stepName: 'Enricher', status: 'running'),
    );
    try {
      final executor = AutogenPipelineExecutor(generator: _generator);
      executor.theoryInjector.injectAll(pack.spots, {});
      executor.boardClassifier?.classifyAll(pack.spots);
      executor.skillLinker.linkAll(pack.spots);
      setState(() {});
      AutogenPipelineDebugStatsService.incrementCurated();
      AutogenPipelineEventLoggerService.log(
        'curated',
        'Curated pack ${pack.id} with ${pack.spots.length} spots',
      );
      _tracker.updateStep(
        _sessionId,
        const AutoGenStepStatus(stepName: 'Enricher', status: 'ok'),
      );
      _showSnack('Enrichment complete for ${pack.id}');
    } catch (e) {
      _failStep('Enricher', e);
    }
  }

  Future<void> _runExporter() async {
    final pack = _pack;
    if (pack == null) {
      _showSnack('Nothing to export');
      return;
    }
    _tracker.updateStep(
      _sessionId,
      const AutoGenStepStatus(stepName: 'Exporter', status: 'running'),
    );
    try {
      final file = await _exporter.export(pack);
      AutogenPipelineEventLoggerService.log(
        'published',
        'Exported ${pack.id} → ${file.path}',
      );
      AutogenPipelineDebugStatsService.incrementPublished();
      _tracker.updateStep(
        _sessionId,
        const AutoGenStepStatus(stepName: 'Exporter', status: 'ok'),
      );
      _showSnack('Exported ${pack.id} to ${file.path}');
    } catch (e) {
      _failStep('Exporter', e);
    }
  }

  Future<void> _runFullPipeline() async {
    final set = _selectedSet;
    if (set == null) {
      _showSnack('Select a template set first');
      return;
    }
    _tracker.updateStep(
      _sessionId,
      const AutoGenStepStatus(stepName: 'Full Pipeline', status: 'running'),
    );
    try {
      final executor = AutogenPipelineExecutor();
      await executor.execute([set], existingYamlPath: 'packs/generated');
      _tracker.updateStep(
        _sessionId,
        const AutoGenStepStatus(stepName: 'Full Pipeline', status: 'ok'),
      );
      _showSnack('Full pipeline completed for ${set.baseSpot.id}');
    } catch (e) {
      _failStep('Full Pipeline', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_busy) const SizedBox(height: 12),
            DropdownButton<TrainingPackTemplateSet>(
              isExpanded: true,
              value: _selectedSet,
              hint: const Text('Select Template Set'),
              items: [
                for (final set in _sets)
                  DropdownMenuItem(
                    value: set,
                    child: Text(set.baseSpot.id),
                  ),
              ],
              onChanged:
                  _busy ? null : (v) => setState(() => _selectedSet = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed:
                      _busy ? null : () => _guard(_runGenerator),
                  child: const Text('Run Generator'),
                ),
                ElevatedButton(
                  onPressed:
                      _busy ? null : () => _guard(_runEnricher),
                  child: const Text('Run Enricher'),
                ),
                ElevatedButton(
                  onPressed:
                      _busy ? null : () => _guard(_runExporter),
                  child: const Text('Run Exporter'),
                ),
                ElevatedButton(
                  onPressed:
                      _busy ? null : () => _guard(_runFullPipeline),
                  child: const Text('Run Full Pipeline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
