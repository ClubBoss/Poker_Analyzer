import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../services/pack_library_service.dart';
import '../services/session_log_service.dart';
import '../services/training_session_launcher.dart';
import '../services/learning_path_stage_gatekeeper_service.dart';
import '../services/learning_path_stage_ui_status_engine.dart';
import '../services/learning_path_completion_engine.dart';
import '../models/session_log.dart';
import '../services/learning_path_progress_tracker_service.dart';
import '../services/smart_stage_unlock_service.dart';
import '../services/learning_path_personalization_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/learning_path_prefs.dart';
import 'learning_path_celebration_screen.dart';
import '../widgets/next_steps_modal.dart';
import '../widgets/stage_progress_chip.dart';
import '../widgets/stage_preview_dialog.dart';

/// Displays all stages of a learning path and allows launching each pack.
class LearningPathScreen extends StatefulWidget {
  final LearningPathTemplateV2 template;
  final String? highlightedStageId;

  const LearningPathScreen({
    super.key,
    required this.template,
    this.highlightedStageId,
  });

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late SessionLogService _logs;
  late TagMasteryService _mastery;
  late LearningPathPrefs _prefs;
  final _gatekeeper = const LearningPathStageGatekeeperService();
  final _smartUnlock = const SmartStageUnlockService();
  final _progressTracker = const LearningPathProgressTrackerService();

  bool _loading = true;
  Map<String, LearningStageUIState> _stageStates = {};
  Map<String, SessionLog> _logsByPack = {};
  Map<String, double> _masteryMap = {};
  Set<String> _reinforced = {};
  bool _celebrationShown = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _stageKeys = {};
  bool _scrollDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logs = context.read<SessionLogService>();
    _mastery = context.read<TagMasteryService>();
    _prefs = context.read<LearningPathPrefs>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final aggregated = _progressTracker.aggregateLogsByPack(_logs.logs);
    final mastery = await _mastery.computeMastery();
    final skillMap =
        LearningPathPersonalizationService.instance.getTagSkillMap();
    final extra = _smartUnlock.getAdditionalUnlockedStageIds(
      progress: aggregated,
      skillMap: skillMap,
      path: widget.template,
    ).toSet();
    final states = <String, LearningStageUIState>{};
    for (int i = 0; i < widget.template.stages.length; i++) {
      final stage = widget.template.stages[i];
      final log = aggregated[stage.packId];
      final correct = log?.correctCount ?? 0;
      final mistakes = log?.mistakeCount ?? 0;
      final total = correct + mistakes;
      final accuracy = total == 0 ? 0.0 : correct / total * 100;
      final done = total >= stage.minHands && accuracy >= stage.requiredAccuracy;
      if (done) {
        states[stage.id] = LearningStageUIState.done;
      } else if (_gatekeeper.isStageUnlocked(
          index: i,
          path: widget.template,
          logs: aggregated,
          additionalUnlockedStageIds: extra)) {
        states[stage.id] = LearningStageUIState.active;
      } else {
        states[stage.id] = LearningStageUIState.locked;
      }
    }
    setState(() {
      _stageStates = states;
      _logsByPack = aggregated;
      _masteryMap = mastery;
      _reinforced = extra;
      _loading = false;
    });

    if (!_scrollDone && widget.highlightedStageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToStage());
    }

    final completedAll = const LearningPathCompletionEngine()
        .isCompleted(widget.template, aggregated);
    if (completedAll && !_celebrationShown && mounted) {
      _celebrationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LearningPathCelebrationScreen(
              path: widget.template,
              onNext: () async {
                await NextStepsModal.show(
                  context,
                  widget.template.id,
                );
              },
            ),
          ),
        );
      });
    }
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

  Future<bool> _isReadyForStage(LearningPathStageModel stage) async {
    final log = _logsByPack[stage.packId];
    final correct = log?.correctCount ?? 0;
    final mistakes = log?.mistakeCount ?? 0;
    final hands = correct + mistakes;
    final accuracy = hands == 0 ? 0.0 : correct / hands * 100;
    if (hands >= stage.minHands && accuracy >= stage.requiredAccuracy) {
      return true;
    }
    var map = _masteryMap;
    if (map.isEmpty) {
      map = await _mastery.computeMastery();
      setState(() => _masteryMap = map);
    }
    if (stage.tags.isEmpty) return false;
    for (final t in stage.tags) {
      if ((map[t.toLowerCase()] ?? 0.0) < 0.9) return false;
    }
    return true;
  }

  Future<void> _handleStageTap(LearningPathStageModel stage) async {
    final ready = _prefs.skipPreviewIfReady && await _isReadyForStage(stage);
    if (ready) {
      await _startStage(stage);
      return;
    }
    final start = await showDialog<bool>(
      context: context,
      builder: (_) => StagePreviewDialog(stage: stage),
    );
    if (start == true) _startStage(stage);
  }

  void _scrollToStage() {
    final id = widget.highlightedStageId;
    if (id == null) return;
    final key = _stageKeys[id];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;
    _scrollDone = true;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildStageTile(LearningPathStageModel stage, int index) {
    final state = _stageStates[stage.id] ?? LearningStageUIState.locked;
    final accent = Theme.of(context).colorScheme.secondary;
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (state) {
      case LearningStageUIState.done:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Завершено';
        break;
      case LearningStageUIState.active:
        icon = Icons.lock_open;
        color = accent;
        label = 'Доступно';
        break;
      case LearningStageUIState.locked:
      default:
        icon = Icons.lock;
        color = Colors.grey;
        label = 'Заблокировано';
        break;
    }
    final grey = state == LearningStageUIState.locked ? Colors.white60 : null;
    final border = state == LearningStageUIState.active
        ? RoundedRectangleBorder(
            side: BorderSide(color: accent, width: 2),
            borderRadius: BorderRadius.circular(4),
          )
        : null;
    final log = _logsByPack[stage.packId];
    Widget? subtitle;
    if (stage.description.isNotEmpty) {
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stage.description, style: TextStyle(color: grey)),
          const SizedBox(height: 2),
          StageProgressChip(
            log: log,
            requiredAccuracy: stage.requiredAccuracy,
            minHands: stage.minHands,
          ),
        ],
      );
    } else {
      subtitle = StageProgressChip(
        log: log,
        requiredAccuracy: stage.requiredAccuracy,
        minHands: stage.minHands,
      );
    }
    final highlight = widget.highlightedStageId == stage.id;
    final key = _stageKeys.putIfAbsent(stage.id, () => GlobalKey());
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: border,
      color: highlight
          ? Colors.amber.withOpacity(0.2)
          : state == LearningStageUIState.locked
              ? Colors.grey.shade800
              : null,
      child: ListTile(
        leading: Text('${index + 1}.', style: TextStyle(color: grey)),
        title: Text(stage.title, style: TextStyle(color: grey)),
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_reinforced.contains(stage.id))
              const Tooltip(
                message: 'Рекомендовано для повторения',
                child: Icon(Icons.star, color: Colors.orange),
              ),
            if (_reinforced.contains(stage.id)) const SizedBox(width: 4),
            if (state == LearningStageUIState.active)
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: 'Preview',
                color: Colors.white70,
                onPressed: () async {
                  final start = await showDialog<bool>(
                    context: context,
                    builder: (_) => StagePreviewDialog(stage: stage),
                  );
                  if (start == true) _startStage(stage);
                },
              ),
            if (state == LearningStageUIState.active) const SizedBox(width: 4),
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
        onTap: state == LearningStageUIState.locked
            ? null
            : () => _handleStageTap(stage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final tags = template.tags;
    return Scaffold(
      appBar: AppBar(
        title: Text(template.title),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                if (!_scrollDone && widget.highlightedStageId != null) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToStage());
                }
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                if (template.description.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      template.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                for (int i = 0; i < template.stages.length; i++)
                  _buildStageTile(template.stages[i], i),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final t in tags) Chip(label: Text(t)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
