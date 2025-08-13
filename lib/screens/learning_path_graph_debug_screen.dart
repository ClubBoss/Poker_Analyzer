import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/learning_graph_engine.dart';
import '../models/learning_path_node.dart';
import '../models/learning_path_session_state.dart';
import '../ui/tools/path_map_visualizer.dart';

/// Debug screen that visualizes the entire learning path graph.
class LearningPathGraphDebugScreen extends StatefulWidget {
  const LearningPathGraphDebugScreen({super.key});

  @override
  State<LearningPathGraphDebugScreen> createState() =>
      _LearningPathGraphDebugScreenState();
}

class _LearningPathGraphDebugScreenState
    extends State<LearningPathGraphDebugScreen> {
  late Future<List<LearningPathNode>> _future;
  String? _currentId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LearningPathNode>> _load() async {
    await LearningPathEngine.instance.initialize();
    final nodes = await LearningPathEngine.instance.orchestrator.loadGraph();
    _currentId = LearningPathEngine.instance.getCurrentNode()?.id;
    return nodes;
  }

  Future<void> _jump(String id) async {
    final state = LearningPathSessionState(
      currentNodeId: id,
      branchChoices: const {},
      completedStageIds: const {},
    );
    await LearningPathEngine.instance.restoreState(state);
    setState(() {
      _currentId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Path Map Visualizer')),
      body: FutureBuilder<List<LearningPathNode>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final nodes = snapshot.data ?? [];
          return PathMapVisualizer(
            nodes: nodes,
            currentNodeId: _currentId,
            onNodeTap: _jump,
          );
        },
      ),
    );
  }
}
