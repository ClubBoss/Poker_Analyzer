import 'package:flutter/material.dart';
import '../services/learning_path_progress_service.dart';
import '../services/training_pack_template_service.dart';
import '../main.dart';
import 'v2/training_pack_play_screen.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LearningStageState>>(
      future: LearningPathProgressService.instance.getCurrentStageState(),
      builder: (context, snapshot) {
        final stages = snapshot.data ?? [];
        return Scaffold(
          appBar: AppBar(title: const Text('📚 Путь обучения')),
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            stage.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
      case LearningItemStatus.available:
        color = Colors.blueGrey.shade700;
        break;
      case LearningItemStatus.locked:
      default:
        color = Colors.grey.shade800;
        break;
    }
    final trailing = item.status == LearningItemStatus.completed
        ? const Icon(Icons.emoji_events, color: Colors.amber)
        : Text('${(item.progress * 100).round()}%');
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
                    final tpl =
                        TrainingPackTemplateService.getById(id, ctx);
                    if (tpl == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Template not found')),
                      );
                      return;
                    }
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) =>
                            TrainingPackPlayScreen(template: tpl, original: tpl),
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  }
}
