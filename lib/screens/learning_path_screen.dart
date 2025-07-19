import 'package:flutter/material.dart';
import '../services/learning_path_progress_service.dart';
import '../services/training_pack_template_service.dart';
import '../main.dart';
import '../widgets/stage_completion_banner.dart';

import '../widgets/suggested_tip_banner.dart';
import 'v2/training_pack_play_screen.dart';
import 'learning_path_completion_screen.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LearningStageState>>(
      future: LearningPathProgressService.instance.getCurrentStageState(),
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
          appBar: AppBar(title: const Text('📚 Путь обучения')),
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: stages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return const SuggestedTipBanner();
                    final stage = stages[index - 1];
                    return _StageSection(stage: stage);
                  },
                ),
        );
      },
    );
  }
}

class _StageSection extends StatelessWidget {
  final LearningStageState stage;
  const _StageSection({required this.stage});

  @override
  Widget build(BuildContext context) {
    final progress = computeStageProgress(stage.items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StageHeaderWithProgress(
          title: stage.title,
          progress: progress,
          showProgress: !stage.isLocked,
        ),
        const SizedBox(height: 8),
        StageCompletionBanner(title: stage.title),
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
