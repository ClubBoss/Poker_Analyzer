import 'package:flutter/material.dart';

import '../models/learning_path_node_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/learning_graph_engine.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/training_pack_launcher_service.dart';
import '../services/skill_tree_node_detail_unlock_hint_service.dart';
import '../widgets/path_node_tile.dart';
import '../widgets/path_node_unlock_hint_overlay.dart';
import 'mini_lesson_screen.dart';
import 'training_pack_preview_screen.dart';

class LearningPathLinearViewScreen extends StatefulWidget {
  final bool showAppBar;
  const LearningPathLinearViewScreen({super.key, this.showAppBar = true});

  @override
  State<LearningPathLinearViewScreen> createState() =>
      _LearningPathLinearViewScreenState();
}

class _LearningPathLinearViewScreenState
    extends State<LearningPathLinearViewScreen> {
  late Future<void> _initFuture;
  List<LearningPathNodeV2> _nodes = [];
  LearningPathNodeV2? _current;
  final Map<String, TrainingPackTemplateV2> _packs = {};

  @override
  void initState() {
    super.initState();
    _initFuture = _load();
  }

  Future<void> _load() async {
    final data = await loadLearningPathData();
    _nodes = data.nodes;
    _current = data.current;
    _packs
      ..clear()
      ..addAll(data.packs);
  }

  void _refresh() {
    setState(() {
      _current =
          LearningPathEngine.instance.getCurrentNode() as LearningPathNodeV2?;
    });
  }

  Future<void> _openCurrent() async {
    final node = _current;
    if (node == null) return;
    if (node.type == LearningPathNodeType.theory) {
      final lesson = MiniLessonLibraryService.instance.getById(
        node.miniLessonId ?? '',
      );
      if (lesson != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
        );
        await LearningPathEngine.instance.markStageCompleted(node.id);
        _refresh();
      }
    } else {
      if (node.dynamicPackId != null) {
        await const TrainingPackLauncherService().launch(node);
        await LearningPathEngine.instance.markStageCompleted(node.id);
        _refresh();
      } else {
        final pack = _packs[node.trainingPackTemplateId];
        if (pack != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrainingPackPreviewScreen(template: pack),
            ),
          );
          await LearningPathEngine.instance.markStageCompleted(node.id);
          _refresh();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _nodes.length,
                itemBuilder: (context, index) {
                  final node = _nodes[index];
                  final currentId = _current?.id;
                  final isCompleted = LearningPathEngine.instance.isCompleted(
                    node.id,
                  );
                  final isCurrent = node.id == currentId;
                  final currentIndex = _nodes.indexWhere(
                    (n) => n.id == currentId,
                  );
                  final nodeIndex = _nodes.indexOf(node);
                  final isBlocked = !isCompleted &&
                      !isCurrent &&
                      nodeIndex > currentIndex &&
                      currentIndex >= 0;
                  final pack =
                      _packs[node.trainingPackTemplateId ?? node.dynamicPackId];
                  final key = GlobalKey();
                  return PathNodeTile(
                    key: key,
                    node: node,
                    pack: pack,
                    isCurrent: isCurrent,
                    isCompleted: isCompleted,
                    isBlocked: isBlocked,
                    onTap: () async {
                      if (isBlocked) {
                        final hint =
                            await const SkillTreeNodeDetailUnlockHintService()
                                .getHint(node.id);
                        if (hint != null) {
                          PathNodeUnlockHintOverlay.show(
                            context: context,
                            targetKey: key,
                            message: hint,
                          );
                        }
                        return;
                      }
                      await LearningPathEngine.instance.markStageCompleted(
                        node.id,
                      );
                      _refresh();
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _openCurrent,
                child: const Text('Продолжить'),
              ),
            ),
          ],
        );
      },
    );
    if (!widget.showAppBar) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Level I: Push/Fold Essentials')),
      body: body,
    );
  }
}
