import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/training_pack_template_service.dart';
import '../services/learning_path_config_loader.dart';
import '../services/learning_path_stage_library.dart';
import '../services/training_progress_service.dart';
import '../models/learning_path_stage_model.dart';
import 'v2/training_pack_play_screen.dart';
import 'learning_progress_stats_screen.dart';

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
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    setState(() => _loading = true);
    final path = _paths[_selected]!;
    await LearningPathConfigLoader.instance.loadPath(path);
    _stages = List.from(LearningPathStageLibrary.instance.stages)
      ..sort((a, b) => a.order.compareTo(b.order));
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
                  builder: (_) => const LearningProgressStatsScreen()),
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
                  DropdownMenuItem(value: name, child: Text(name)),
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
                  return _DynamicStageTile(stage: stage);
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
  const _DynamicStageTile({required this.stage});

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
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text(stage.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stage.description.isNotEmpty)
                  Text(stage.description,
                      style: const TextStyle(color: Colors.white70)),
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
                  child: Text('$percent%',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                final tpl =
                    TrainingPackTemplateService.getById(stage.packId, context);
                if (tpl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template not found')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TrainingPackPlayScreen(template: tpl, original: tpl),
                  ),
                );
              },
              child: Text(buttonLabel),
            ),
          ),
        );
      },
    );
  }
}

