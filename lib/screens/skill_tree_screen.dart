import 'package:flutter/material.dart';

import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_node_progress_tracker.dart';
import '../services/skill_tree_unlock_evaluator.dart';
import '../screens/skill_tree_node_detail_view.dart';

class SkillTreeScreen extends StatefulWidget {
  final String category;
  const SkillTreeScreen({super.key, required this.category});

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  SkillTree? _tree;
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
    final res = SkillTreeLibraryService.instance.getTree(widget.category);
    final tree = res?.tree;
    if (tree == null) {
      setState(() => _loading = false);
      return;
    }
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.isCompleted(''); // ensure data loaded
    final completed = tracker.completedNodeIds.value;
    final evaluator = SkillTreeUnlockEvaluator(progress: tracker);
    final unlocked = evaluator.getUnlockedNodes(tree).map((n) => n.id).toSet();
    setState(() {
      _tree = tree;
      _unlocked = unlocked;
      _completed = completed;
      _loading = false;
    });
  }

  Future<void> _openNode(SkillTreeNodeModel node) async {
    if (_completed.contains(node.id)) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillTreeNodeDetailView(node: node),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tree = _tree;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (tree == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: const Center(child: Text('No skill tree found')),
      );
    }
    final nodes = tree.nodes.values.toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    final levels = <int, List<SkillTreeNodeModel>>{};
    for (final n in nodes) {
      levels.putIfAbsent(n.level, () => []).add(n);
    }
    final children = <Widget>[];
    final sortedLevels = levels.keys.toList()..sort();
    for (final lvl in sortedLevels) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Level $lvl',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      for (final n in levels[lvl]!) {
        final completed = _completed.contains(n.id);
        final unlocked = _unlocked.contains(n.id) || completed;
        IconData icon;
        Color color;
        String status;
        if (completed) {
          icon = Icons.check_circle;
          color = Colors.green;
          status = 'Completed';
        } else if (unlocked) {
          icon = Icons.radio_button_unchecked;
          color = Colors.amber;
          status = 'Unlocked';
        } else {
          icon = Icons.lock;
          color = Colors.grey;
          status = 'Locked';
        }
        children.add(
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(n.title),
            subtitle: Text(status),
            onTap: unlocked ? () => _openNode(n) : null,
          ),
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: ListView(children: children),
    );
  }
}
