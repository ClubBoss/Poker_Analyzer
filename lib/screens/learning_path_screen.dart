import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/training_pack_template_service.dart';
import '../services/learning_path_config_loader.dart';
import '../services/learning_path_stage_library.dart';
import '../services/training_progress_service.dart';
import '../services/training_pack_stats_service.dart';
import '../models/learning_path_stage_model.dart';
import 'v2/training_pack_play_screen.dart';
import 'learning_progress_stats_screen.dart';
import '../utils/snackbar_util.dart';

enum StageStatus { completed, open, locked }

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  final Map<String, String> _paths = const {
    'Beginner': 'assets/learning_paths/beginner_path.yaml',
    'ICM': 'assets/learning_paths/icm_multiway_path.yaml',
    'Cash': 'assets/learning_paths/push_fold_cash.yaml',
    'Live': 'assets/learning_paths/live_path.yaml',
  };

  static const _prefsKey = 'selected_learning_path';

  String _selected = 'Beginner';
  List<LearningPathStageModel> _stages = [];
  bool _loading = true;
  final Map<String, int> _progressByPath = {};
  final Map<String, int> _completedStagesByPath = {};
  final Map<String, int> _totalStagesByPath = {};
  final Map<String, StageStatus> _stageStatus = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      for (final entry in _paths.entries) {
        if (entry.value.endsWith(stored)) {
          _selected = entry.key;
          break;
        }
      }
    }
    await _computeAllProgress();
    await _loadCurrent();
  }

  Future<void> _computeAllProgress() async {
    final loader = LearningPathConfigLoader.instance;
    final library = LearningPathStageLibrary.instance;
    for (final entry in _paths.entries) {
      library.clear();
      await loader.loadPath(entry.value);
      final stages = List<LearningPathStageModel>.from(library.stages);
      double sum = 0;
      int completed = 0;
      for (final s in stages) {
        final prog = await TrainingProgressService.instance.getProgress(
          s.packId,
        );
        sum += prog;
        if (prog >= 1.0) completed++;
      }
      final pct = stages.isEmpty ? 0 : (sum / stages.length * 100).round();
      _progressByPath[entry.key] = pct;
      _completedStagesByPath[entry.key] = completed;
      _totalStagesByPath[entry.key] = stages.length;
    }
    setState(() {});
  }

  Map<String, StageStatus> _computeStageStatus(
    List<LearningPathStageModel> orderedStages,
    Map<String, double> progressMap,
    Map<String, double> accuracyMap, {
    int openCount = 2,
  }) {
    final map = <String, StageStatus>{};
    var open = 0;
    for (final stage in orderedStages) {
      final prog = progressMap[stage.id] ?? 0.0;
      if (prog >= 1.0) {
        map[stage.id] = StageStatus.completed;
      } else {
        bool unlocked = true;
        final cond = stage.unlockCondition;
        if (cond != null) {
          if (cond.dependsOn != null) {
            final depProg = progressMap[cond.dependsOn!] ?? 0.0;
            final depAcc = accuracyMap[cond.dependsOn!] ?? 0.0;
            final reqAcc = cond.minAccuracy?.toDouble() ?? 0.0;
            if (!(depProg >= 1.0 && depAcc >= reqAcc)) {
              unlocked = false;
            }
          }
        }
        if (unlocked && open < openCount) {
          map[stage.id] = StageStatus.open;
          open++;
        } else {
          map[stage.id] = StageStatus.locked;
        }
      }
    }
    return map;
  }

  Future<void> _loadCurrent() async {
    setState(() => _loading = true);
    final path = _paths[_selected]!;
    final library = LearningPathStageLibrary.instance;
    library.clear();
    await LearningPathConfigLoader.instance.loadPath(path);
    final stages = List<LearningPathStageModel>.from(library.stages)
      ..sort((a, b) => a.order.compareTo(b.order));

    final pairs = <MapEntry<LearningPathStageModel, double>>[];
    final progressMap = <String, double>{};
    final accuracyMap = <String, double>{};
    double sum = 0;
    int completed = 0;
    for (final s in stages) {
      final prog = await TrainingProgressService.instance.getProgress(s.packId);
      sum += prog;
      if (prog >= 1.0) completed++;
      pairs.add(MapEntry(s, prog));
      progressMap[s.id] = prog;
      final stat = await TrainingPackStatsService.getStats(s.packId);
      accuracyMap[s.id] = (stat?.accuracy ?? 0.0) * 100;
    }
    final pct = stages.isEmpty ? 0 : (sum / stages.length * 100).round();
    _progressByPath[_selected] = pct;
    _completedStagesByPath[_selected] = completed;
    _totalStagesByPath[_selected] = stages.length;

    _stageStatus
      ..clear()
      ..addAll(_computeStageStatus(stages, progressMap, accuracyMap));

    pairs.sort((a, b) {
      final aDone = a.value >= 1.0;
      final bDone = b.value >= 1.0;
      if (aDone != bDone) return aDone ? 1 : -1;
      return a.key.order.compareTo(b.key.order);
    });
    _stages = [for (final p in pairs) p.key];

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Путь обучения'),
        actions: [
          IconButton(
            icon: const Text('📊', style: TextStyle(fontSize: 20)),
            tooltip: 'Статистика',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LearningProgressStatsScreen(),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: _selected,
              onChanged: (v) async {
                if (v == null) return;
                final prefs = await SharedPreferences.getInstance();
                final file = _paths[v]!.split('/').last;
                await prefs.setString(_prefsKey, file);
                setState(() => _selected = v);
                await _loadCurrent();
              },
              items: [
                for (final name in _paths.keys)
                  DropdownMenuItem(
                    value: name,
                    child: Text(
                      _progressByPath.containsKey(name)
                          ? '$name · ${_progressByPath[name]}% · '
                                '${_completedStagesByPath[name] ?? 0}/'
                                '${_totalStagesByPath[name] ?? 0}'
                          : name,
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _stages.length,
                itemBuilder: (context, index) {
                  final stage = _stages[index];
                  final status = _stageStatus[stage.id] ?? StageStatus.locked;
                  return _DynamicStageTile(
                    stage: stage,
                    status: status,
                    onReturn: _loadCurrent,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DynamicStageTile extends StatelessWidget {
  final LearningPathStageModel stage;
  final StageStatus status;
  final Future<void> Function()? onReturn;

  const _DynamicStageTile({
    required this.stage,
    required this.status,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: TrainingProgressService.instance.getProgress(stage.packId),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;
        final percent = (progress * 100).round();
        final buttonLabel = progress == 0
            ? 'Начать'
            : (progress >= 1.0 ? 'Повторить' : 'Продолжить');
        String prefix;
        switch (status) {
          case StageStatus.completed:
            prefix = '✅';
            break;
          case StageStatus.open:
            prefix = '🔓';
            break;
          case StageStatus.locked:
          default:
            prefix = '🔒';
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text('$prefix ${stage.title}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stage.description.isNotEmpty)
                  Text(
                    stage.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.orange,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: status == StageStatus.locked
                  ? null
                  : () async {
                      final tpl = TrainingPackTemplateService.getById(
                        stage.packId,
                        context,
                      );
                      if (tpl == null) {
                        SnackbarUtil.showMessage(context, 'Template not found');
                        return;
                      }
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TrainingPackPlayScreen(template: tpl, original: tpl),
                        ),
                      );
                      if (onReturn != null) await onReturn!();
                    },
              child: Text(buttonLabel),
            ),
          ),
        );
      },
    );
  }
}
