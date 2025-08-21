import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_node_progress_tracker.dart';
import '../services/skill_tree_unlock_evaluator.dart';
import 'skill_tree_node_detail_screen.dart';

/// Visual map of all nodes in a skill tree track.
class SkillTreeLearningMapScreen extends StatefulWidget {
  static const route = '/skill-tree/learning-map';
  final String trackId;

  const SkillTreeLearningMapScreen({super.key, required this.trackId});

  @override
  State<SkillTreeLearningMapScreen> createState() =>
      _SkillTreeLearningMapScreenState();
}

class _SkillTreeLearningMapScreenState
    extends State<SkillTreeLearningMapScreen> {
  SkillTree? _track;
  Set<String> _unlocked = {};
  Set<String> _completed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SkillTreeLibraryService.instance.reload();
    final res = SkillTreeLibraryService.instance.getTrack(widget.trackId);
    final tree = res?.tree;
    if (tree == null) {
      setState(() => _loading = false);
      return;
    }
    final progress = SkillTreeNodeProgressTracker.instance;
    await progress.isCompleted('');
    final evaluator = SkillTreeUnlockEvaluator(progress: progress);
    final unlocked = evaluator.getUnlockedNodes(tree).map((n) => n.id).toSet();
    final completed = progress.completedNodeIds.value
        .where(tree.nodes.containsKey)
        .toSet();
    setState(() {
      _track = tree;
      _unlocked = unlocked..addAll(completed);
      _completed = completed;
      _loading = false;
    });
  }

  Future<void> _openNode(SkillTreeNodeModel node) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillTreeNodeDetailScreen(
          node: node,
          unlocked: _unlocked.contains(node.id),
          track: _track!,
          unlockedNodeIds: _unlocked,
          completedNodeIds: _completed,
        ),
      ),
    );
    await _load();
  }

  Widget _buildNode(SkillTreeNodeModel node) {
    final completed = _completed.contains(node.id);
    final unlocked = _unlocked.contains(node.id);
    IconData icon;
    Color color;
    if (completed) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (unlocked) {
      icon = Icons.auto_awesome;
      color = Colors.amber;
    } else {
      icon = Icons.lock;
      color = Colors.grey;
    }
    return GestureDetector(
      onTap: unlocked ? () => _openNode(node) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Icon(icon, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tree = _track;
    if (tree == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.trackId)),
        body: const Center(child: Text('Track not found')),
      );
    }

    final graph = Graph();
    final map = <String, Node>{};
    for (final n in tree.nodes.values) {
      final node = Node(_buildNode(n));
      map[n.id] = node;
      graph.addNode(node);
    }
    for (final n in tree.nodes.values) {
      for (final id in n.unlockedNodeIds) {
        final from = map[n.id];
        final to = map[id];
        if (from != null && to != null) {
          graph.addEdge(from, to);
        }
      }
    }

    final builder = BuchheimWalkerAlgorithm(
      BuchheimWalkerConfiguration()
        ..siblingSeparation = 20
        ..levelSeparation = 40
        ..subtreeSeparation = 20,
    );

    final title = tree.roots.isNotEmpty
        ? tree.roots.first.title
        : widget.trackId;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.1,
        maxScale: 2.0,
        child: GraphView(graph: graph, algorithm: builder),
      ),
    );
  }
}
