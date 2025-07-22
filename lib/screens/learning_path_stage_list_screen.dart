import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../models/learning_track_progress_model.dart';
import '../services/learning_track_progress_service.dart';
import '../services/training_path_progress_service_v2.dart';
import '../services/learning_path_gatekeeper_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/session_log_service.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/learning_path_progress_tracker_service.dart';
import '../widgets/learning_stage_tile.dart';

/// Displays stages of a learning path with progress indicators.
class LearningPathStageListScreen extends StatefulWidget {
  final LearningPathTemplateV2 path;
  const LearningPathStageListScreen({super.key, required this.path});

  @override
  State<LearningPathStageListScreen> createState() =>
      _LearningPathStageListScreenState();
}

class _LearningPathStageListScreenState
    extends State<LearningPathStageListScreen> {
  late SessionLogService _logs;
  late TrainingPathProgressServiceV2 _progress;
  late LearningPathGatekeeperService _gatekeeper;
  late LearningTrackProgressService _service;
  final _tracker = const LearningPathProgressTrackerService();

  LearningTrackProgressModel _model =
      const LearningTrackProgressModel(stages: []);
  Map<String, String> _progressStrings = {};
  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _logs = context.read<SessionLogService>();
      _progress = TrainingPathProgressServiceV2(logs: _logs);
      _gatekeeper = LearningPathGatekeeperService(
        progress: _progress,
        mastery: context.read<TagMasteryService>(),
      );
      _service = LearningTrackProgressService(
        progress: _progress,
        gatekeeper: _gatekeeper,
      );
      _load();
      _initialized = true;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _logs.load();
    final model = await _service.build(widget.path.id);
    final progressStrings =
        _tracker.computeProgressStrings(widget.path, _logs.logs);
    if (!mounted) return;
    setState(() {
      _model = model;
      _progressStrings = progressStrings;
      _loading = false;
    });
  }

  Future<void> _startStage(LearningPathStageModel stage) async {
    final template = await PackLibraryService.instance.getById(stage.packId);
    if (template == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training pack not found')),
      );
      return;
    }
    await const TrainingSessionLauncher().launch(template);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.path.stages;
    return Scaffold(
      appBar: AppBar(title: Text(widget.path.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  final status =
                      _model.statusFor(stage.id)?.status ?? StageStatus.locked;
                  final progress = _progressStrings[stage.id] ?? '';
                  return LearningStageTile(
                    stage: stage,
                    status: status,
                    subtitle: progress,
                    onTap: () => _startStage(stage),
                  );
                },
              ),
            ),
    );
  }
}

