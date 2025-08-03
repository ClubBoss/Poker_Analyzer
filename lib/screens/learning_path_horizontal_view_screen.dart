import 'package:flutter/material.dart';

import '../models/learning_path_node_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/learning_graph_engine.dart';
import '../services/learning_path_loader.dart';
import '../services/mini_lesson_library_service.dart';
import '../widgets/path_node_tile.dart';
import 'mini_lesson_screen.dart';
import 'training_pack_preview_screen.dart';

class LearningPathHorizontalViewScreen extends StatefulWidget {
  const LearningPathHorizontalViewScreen({super.key});

  @override
  State<LearningPathHorizontalViewScreen> createState() =>
      _LearningPathHorizontalViewScreenState();
}

class _LearningPathHorizontalViewScreenState
    extends State<LearningPathHorizontalViewScreen> {
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
      final lesson =
          MiniLessonLibraryService.instance.getById(node.miniLessonId ?? '');
      if (lesson != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MiniLessonScreen(lesson: lesson),
          ),
        );
        await LearningPathEngine.instance.markStageCompleted(node.id);
        _refresh();
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level I: Push/Fold Essentials')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: _nodes.map((node) {
                      final currentId = _current?.id;
                      final isCompleted =
                          LearningPathEngine.instance.isCompleted(node.id);
                      final isCurrent = node.id == currentId;
                      final currentIndex =
                          _nodes.indexWhere((n) => n.id == currentId);
                      final nodeIndex = _nodes.indexOf(node);
                      final isBlocked = !isCompleted &&
                          !isCurrent &&
                          nodeIndex > currentIndex &&
                          currentIndex >= 0;
                      final pack = _packs[node.trainingPackTemplateId];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 200,
                          child: PathNodeTile(
                            node: node,
                            pack: pack,
                            isCurrent: isCurrent,
                            isCompleted: isCompleted,
                            isBlocked: isBlocked,
                            onTap: () async {
                              await LearningPathEngine.instance
                                  .markStageCompleted(node.id);
                              _refresh();
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
      ),
    );
  }
}

