import 'package:flutter/material.dart';

import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_track_progress_service.dart';
import '../services/skill_tree_track_celebration_service.dart';
import '../widgets/skill_tree_stage_list_builder.dart';
import '../widgets/skill_tree_progress_header.dart';
import 'skill_tree_node_detail_screen.dart';

/// Renders the full learning path for a skill track.
class SkillTreePathScreen extends StatefulWidget {
  final String trackId;
  const SkillTreePathScreen({super.key, required this.trackId});

  @override
  State<SkillTreePathScreen> createState() => _SkillTreePathScreenState();
}

class _SkillTreePathScreenState extends State<SkillTreePathScreen> {
  final _listBuilder = const SkillTreeStageListBuilder();

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
    final progress = SkillTreeTrackProgressService();
    final unlocked = await progress.getUnlockedNodeIds(widget.trackId);
    final completed = await progress.getCompletedNodeIds(widget.trackId);
    if (!mounted) return;
    setState(() {
      _track = tree;
      _unlocked = unlocked;
      _completed = completed;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SkillTreeTrackCelebrationService.instance
          .maybeCelebrate(context, widget.trackId);
    });
  }

  Future<void> _openNode(SkillTreeNodeModel node) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillTreeNodeDetailScreen(
          node: node,
          unlocked: _unlocked.contains(node.id),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final tree = _track;
    if (tree == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.trackId)),
        body: const Center(child: Text('Track not found')),
      );
    }
    final nodes = tree.nodes.values.toList()
      ..sort((a, b) => a.level.compareTo(b.level));

    final list = _listBuilder.build(
      allNodes: nodes,
      unlockedNodeIds: _unlocked,
      completedNodeIds: _completed,
      padding: const EdgeInsets.all(12),
      spacing: 20,
      onNodeTap: _openNode,
    );

    final title =
        tree.roots.isNotEmpty ? tree.roots.first.title : widget.trackId;

    final header = Padding(
      padding: const EdgeInsets.all(12),
      child: SkillTreeProgressHeader(trackId: widget.trackId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          header,
          Expanded(child: list),
        ],
      ),
    );
  }
}
