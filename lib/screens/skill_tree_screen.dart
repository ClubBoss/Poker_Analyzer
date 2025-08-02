import 'package:flutter/material.dart';

import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_node_progress_tracker.dart';
import '../services/skill_tree_unlock_evaluator.dart';
import '../services/skill_tree_stage_gate_evaluator.dart';
import '../services/skill_tree_stage_completion_evaluator.dart';
import '../services/skill_tree_stage_unlock_overlay_builder.dart';
import '../services/skill_tree_stage_gate_celebration_overlay.dart';
import '../services/skill_tree_unlock_notification_service.dart';
import '../widgets/skill_tree_stage_header_builder.dart';
import '../screens/skill_tree_node_detail_screen.dart';
import '../widgets/skill_tree_node_block_reason_widget.dart';

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
  Set<int> _unlockedStages = {};
  Set<int> _completedStages = {};
  bool _loading = true;
  final _overlayBuilder = const SkillTreeStageUnlockOverlayBuilder();
  final _headerBuilder = const SkillTreeStageHeaderBuilder();
  final _unlockNotify = SkillTreeUnlockNotificationService();
  final _stageCelebrator = SkillTreeStageGateCelebrationOverlay();

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

    const gateEval = SkillTreeStageGateEvaluator();
    const compEval = SkillTreeStageCompletionEvaluator();
    final unlockedStages =
        gateEval.getUnlockedStages(tree, completed).toSet();
    final completedStages =
        compEval.getCompletedStages(tree, completed).toSet();

    setState(() {
      _tree = tree;
      _unlocked = unlocked;
      _completed = completed;
      _unlockedStages = unlockedStages;
      _completedStages = completedStages;
      _loading = false;
    });
    if (mounted) {
      await _unlockNotify.maybeNotify(context, tree);
      if (!mounted) return;
      await _stageCelebrator.maybeCelebrate(context, tree);
    }
  }

  Future<void> _openNode(SkillTreeNodeModel node) async {
    if (_completed.contains(node.id)) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillTreeNodeDetailScreen(
          node: node,
          track: _tree!,
          unlockedNodeIds: _unlocked,
          completedNodeIds: _completed,
        ),
      ),
    );
    await _load();
  }

  void _showLockReason(SkillTreeNodeModel node) {
    final width = MediaQuery.of(context).size.width;
    final widgetContent = SkillTreeNodeBlockReasonWidget(nodeId: node.id);
    if (width > 600) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: const Text('How to unlock this stage'),
          content: widgetContent,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How to unlock this stage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                widgetContent,
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
      final isUnlockedStage = _unlockedStages.contains(lvl);
      Widget? overlay;
      if (!isUnlockedStage) {
        overlay = _overlayBuilder.buildOverlay(
          level: lvl,
          isUnlocked: isUnlockedStage,
          isCompleted: _completedStages.contains(lvl),
        );
      }
      final header = _headerBuilder.buildHeader(
        level: lvl,
        nodes: levels[lvl]!,
        unlockedNodeIds: _unlocked,
        completedNodeIds: _completed,
        overlay: overlay,
      );
      children.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: header,
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
            onTap: () =>
                unlocked ? _openNode(n) : _showLockReason(n),
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
