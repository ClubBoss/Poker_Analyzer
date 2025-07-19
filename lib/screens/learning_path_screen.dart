import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/learning_path_progress_service.dart';
import '../services/training_pack_template_service.dart';
import '../main.dart';
import '../widgets/stage_completion_banner.dart';

import '../widgets/suggested_tip_banner.dart';
import '../widgets/learning_path_recommendation_banner.dart';
import 'v2/training_pack_play_screen.dart';
import 'learning_path_completion_screen.dart';
import 'learning_progress_stats_screen.dart';

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late Future<List<LearningStageState>> _future;

  @override
  void initState() {
    super.initState();
    _future = LearningPathProgressService.instance.getCurrentStageState();
  }

  Future<void> _reload() async {
    setState(() {
      _future = LearningPathProgressService.instance.getCurrentStageState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LearningStageState>>(
      future: _future,
      builder: (context, snapshot) {
        final stages = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.done) {
          LearningPathProgressService.instance.isAllStagesCompleted().then((done) {
            if (done && context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LearningPathCompletionScreen(),
                ),
              );
            }
          });
        }

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
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: stages.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) return const SuggestedTipBanner();
                    if (index == 1) return const LearningPathRecommendationBanner();
                    final stage = stages[index - 2];
                    return _StageSection(stage: stage, onReset: _reload);
                  },
                ),
        );
      },
    );
  }
}

class _StageSection extends StatelessWidget {
  final LearningStageState stage;
  final Future<void> Function() onReset;
  const _StageSection({required this.stage, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final progress = computeStageProgress(stage.items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StageHeaderWithProgress(
          title: stage.title,
          levelIndex: stage.levelIndex,
          goal: stage.goal,
          goalHint: stage.goalHint,
          tip: stage.tip,
          progress: progress,
          showProgress: !stage.isLocked,
        ),
        const SizedBox(height: 8),
        StageCompletionBanner(
          title: stage.title,
          levelIndex: stage.levelIndex,
          goal: stage.goal,
        ),
        if (LearningPathProgressService.instance
            .isStageCompleted(stage.items))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ElevatedButton.icon(
              icon: const Text('🔄'),
              label: Text(AppLocalizations.of(context)?.resetStage ??
                  'Reset Stage'),
              onPressed: () async {
                final l = AppLocalizations.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title:
                        Text(l?.resetStagePrompt(stage.title) ?? 'Reset stage?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l?.cancel ?? 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l?.reset ?? 'Reset'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await LearningPathProgressService.instance
                      .resetStage(stage.title);
                  // ignore: avoid_print
                  print('Stage reset: ${stage.title}');
                  await onReset();
                }
              },
            ),
          ),
        const SizedBox(height: 8),
        for (int i = 0; i < stage.items.length; i++)
          LearningStageTile(item: stage.items[i], index: i),
      ],
    );
  }
}

class LearningStageTile extends StatefulWidget {
  final LearningStageItem item;
  final int index;
  const LearningStageTile({super.key, required this.item, required this.index});

  @override
  State<LearningStageTile> createState() => _LearningStageTileState();
}

class _LearningStageTileState extends State<LearningStageTile> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    Color color;
    switch (item.status) {
      case LearningItemStatus.completed:
        color = Colors.green.shade700;
        break;
      case LearningItemStatus.inProgress:
        color = Colors.yellow.shade700;
        break;
      case LearningItemStatus.available:
        color = Colors.blueGrey.shade700;
        break;
      case LearningItemStatus.locked:
      default:
        color = Colors.grey.shade800;
        break;
    }
    late final Widget trailing;
    switch (item.status) {
      case LearningItemStatus.completed:
        trailing = const Icon(Icons.emoji_events, color: Colors.amber);
        break;
      case LearningItemStatus.inProgress:
        trailing = const Text('Продолжить');
        break;
      case LearningItemStatus.available:
        trailing = const Text('Начать');
        break;
      case LearningItemStatus.locked:
      default:
        trailing = Text('${(item.progress * 100).round()}%');
        break;
    }
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.1),
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Card(
          color: color,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(item.icon, color: Colors.white),
            title: Text(item.title),
            trailing: trailing,
            onTap: item.status == LearningItemStatus.locked
                ? null
                : () async {
                    final ctx = navigatorKey.currentContext ?? context;
                    final id = item.templateId;
                    if (id == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Template not found')),
                      );
                      return;
                    }
                    final tpl = TrainingPackTemplateService.getById(id, ctx);
                    if (tpl == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Template not found')),
                      );
                      return;
                    }
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackPlayScreen(
                            template: tpl, original: tpl),
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  }
}

double computeStageProgress(List<LearningStageItem> items) {
  if (items.isEmpty) return 0.0;
  var sum = 0.0;
  for (final item in items) {
    switch (item.status) {
      case LearningItemStatus.completed:
        sum += 1.0;
        break;
      case LearningItemStatus.available:
        sum += 0.5;
        break;
      case LearningItemStatus.inProgress:
        sum += 0.75;
        break;
      case LearningItemStatus.locked:
      default:
        break;
    }
  }
  return sum / items.length;
}
