import 'package:flutter/material.dart';

import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_track_progress_service.dart';
import '../services/skill_tree_track_celebration_service.dart';
import '../services/track_milestone_unlocker_service.dart';
import '../services/stage_auto_scroll_service.dart';
import '../widgets/skill_tree_stage_list_builder.dart';
import '../widgets/skill_tree_track_overview_header.dart';
import '../widgets/skill_tree_stage_badge_legend_widget.dart';
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
  final _autoScroll = const StageAutoScrollService();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _stageKeys = {};

  SkillTree? _track;
  Set<String> _unlocked = {};
  Set<String> _completed = {};
  final Set<String> _justUnlocked = {};
  List<String> _newTheoryNodeIds = [];
  List<String> _newPracticeNodeIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hadPrev = _unlocked.isNotEmpty;

    await TrackMilestoneUnlockerService.instance.initializeMilestones(
      widget.trackId,
    );
    await SkillTreeLibraryService.instance.reload();
    final res = SkillTreeLibraryService.instance.getTrack(widget.trackId);
    final tree = res?.tree;
    if (tree == null) {
      setState(() => _loading = false);
      return;
    }
    final nodes = tree.nodes.values.toList();
    final progress = SkillTreeTrackProgressService();
    final unlocked = await progress.getUnlockedNodeIds(widget.trackId);
    final completed = await progress.getCompletedNodeIds(widget.trackId);

    final newlyUnlocked = unlocked.difference(_unlocked);
    final newTheoryNodeIds = newlyUnlocked
        .where((id) => tree.nodes[id]?.theoryLessonId.isNotEmpty ?? false)
        .toList();
    final newPracticeNodeIds = newlyUnlocked
        .where((id) => tree.nodes[id]?.trainingPackId.isNotEmpty ?? false)
        .toList();
    final hasNewTheory = newTheoryNodeIds.isNotEmpty;
    final hasNewPractice = newPracticeNodeIds.isNotEmpty;

    final blocks = _listBuilder.stageMarker.build(nodes);
    for (final block in blocks) {
      _stageKeys.putIfAbsent(block.stageIndex, () => GlobalKey());
    }

    if (!mounted) return;
    setState(() {
      _track = tree;
      _unlocked = unlocked;
      _completed = completed;
      _loading = false;
      _newTheoryNodeIds = newTheoryNodeIds;
      _newPracticeNodeIds = newPracticeNodeIds;
      if (hadPrev) {
        _justUnlocked.addAll(newlyUnlocked);
      }
    });
    if (hadPrev && hasNewTheory) {
      _showTheoryUnlockBanner();
    }
    if (hadPrev && hasNewPractice) {
      _showPracticeUnlockBanner();
    }
    if (hadPrev) {
      for (final id in newlyUnlocked) {
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _justUnlocked.remove(id);
          });
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SkillTreeTrackCelebrationService.instance.maybeCelebrate(
        context,
        widget.trackId,
      );
      _autoScroll.scrollToFirstIncompleteStage(
        context: context,
        controller: _scrollController,
        allNodes: nodes,
        unlockedNodeIds: _unlocked,
        completedNodeIds: _completed,
        stageKeys: _stageKeys,
      );
    });
  }

  void _showTheoryUnlockBanner() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    final banner = MaterialBanner(
      backgroundColor: Colors.blue,
      content: const Text(
        '📘 New Theory Available!',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            messenger.clearMaterialBanners();
            final nodeId =
                _newTheoryNodeIds.isNotEmpty ? _newTheoryNodeIds.first : null;
            final node = nodeId != null ? _track?.nodes[nodeId] : null;
            if (node != null) {
              await _openNode(node);
            }
          },
          child: const Text(
            'View Theory',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
    messenger.showMaterialBanner(banner);
    Future.delayed(const Duration(seconds: 3), () {
      messenger.clearMaterialBanners();
    });
  }

  void _showPracticeUnlockBanner() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    final banner = MaterialBanner(
      backgroundColor: Colors.blue,
      content: const Text(
        '🎯 New Practice Available!',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            messenger.clearMaterialBanners();
            final nodeId =
                _newPracticeNodeIds.isNotEmpty ? _newPracticeNodeIds.first : null;
            final node = nodeId != null ? _track?.nodes[nodeId] : null;
            if (node != null) {
              await _openNode(node);
            }
          },
          child: const Text(
            'View Practice',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
    messenger.showMaterialBanner(banner);
    Future.delayed(const Duration(seconds: 3), () {
      messenger.clearMaterialBanners();
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final nodes = tree.nodes.values.toList()
      ..sort((a, b) => a.level.compareTo(b.level));

    final list = _listBuilder.build(
      allNodes: nodes,
      unlockedNodeIds: _unlocked,
      completedNodeIds: _completed,
      justUnlockedNodeIds: _justUnlocked,
      padding: const EdgeInsets.all(12),
      spacing: 20,
      onNodeTap: _openNode,
      stageKeys: _stageKeys,
      controller: _scrollController,
    );

    final title = tree.roots.isNotEmpty
        ? tree.roots.first.title
        : widget.trackId;

    final header = Padding(
      padding: const EdgeInsets.all(12),
      child: SkillTreeTrackOverviewHeader(trackId: widget.trackId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SkillTreeStageBadgeLegendWidget(),
          Expanded(child: list),
        ],
      ),
    );
  }
}
