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
import '../services/banner_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Map<int, String> _stageTitles = {};
  final GlobalKey _listKey = GlobalKey();
  int _currentStage = 0;
  static const double _stickyHeaderHeight = 36;

  SkillTree? _track;
  Set<String> _unlocked = {};
  Set<String> _completed = {};
  final Set<String> _justUnlocked = {};
  List<String> _newTheoryNodeIds = [];
  List<String> _newPracticeNodeIds = [];
  bool _loading = true;
  final Set<int> _foldedStages = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

    final prefs = await SharedPreferences.getInstance();
    final blocks = _listBuilder.stageMarker.build(nodes);
    final folded = <int>{};
    _stageKeys.clear();
    _stageTitles.clear();
    for (final block in blocks) {
      _stageKeys[block.stageIndex] = GlobalKey();
      if (block.nodes.isNotEmpty) {
        _stageTitles[block.stageIndex] = block.nodes.first.title;
      }
      final allCompleted = block.nodes.every((n) => completed.contains(n.id));
      if (allCompleted) {
        final key = _foldKey(block.stageIndex);
        final isFolded = prefs.getBool(key) ?? true;
        if (isFolded) folded.add(block.stageIndex);
      }
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
      _foldedStages
        ..clear()
        ..addAll(folded);
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
      _onScroll();
    });
  }

  void _showTheoryUnlockBanner() {
    final banner = MaterialBanner(
      backgroundColor: Colors.blue,
      content: const Text(
        '📘 New Theory Available!',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            BannerQueueService.instance.dismissCurrent();
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
    BannerQueueService.instance.queue(banner);
  }

  void _showPracticeUnlockBanner() {
    final banner = MaterialBanner(
      backgroundColor: Colors.blue,
      content: const Text(
        '🎯 New Practice Available!',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            BannerQueueService.instance.dismissCurrent();
            final nodeId = _newPracticeNodeIds.isNotEmpty
                ? _newPracticeNodeIds.first
                : null;
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
    BannerQueueService.instance.queue(banner);
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

  String _foldKey(int stage) => 'stage_fold_${widget.trackId}_$stage';

  Future<void> _toggleStageFold(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_foldedStages.contains(stage)) {
        _foldedStages.remove(stage);
      } else {
        _foldedStages.add(stage);
      }
    });
    await prefs.setBool(_foldKey(stage), _foldedStages.contains(stage));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    final listTop = listBox.localToGlobal(Offset.zero).dy;
    final entries = _stageKeys.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    int current = entries.isNotEmpty ? entries.first.key : 0;
    for (final e in entries) {
      final ctx = e.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero).dy;
      if (pos - listTop <= 0) {
        current = e.key;
      } else {
        break;
      }
    }
    if (current != _currentStage) {
      setState(() => _currentStage = current);
    }
  }

  Widget _buildStickyBanner() {
    final title = _stageTitles[_currentStage];
    final label = title == null || title.isEmpty
        ? 'Stage $_currentStage'
        : 'Stage $_currentStage - $title';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(label),
        height: _stickyHeaderHeight,
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
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
    final nodes = tree.nodes.values.toList()
      ..sort((a, b) => a.level.compareTo(b.level));

    final list = KeyedSubtree(
      key: _listKey,
      child: _listBuilder.build(
        allNodes: nodes,
        unlockedNodeIds: _unlocked,
        completedNodeIds: _completed,
        justUnlockedNodeIds: _justUnlocked,
        padding: EdgeInsets.fromLTRB(
          12,
          12 + _stickyHeaderHeight,
          12,
          12,
        ),
        spacing: 20,
        onNodeTap: _openNode,
        stageKeys: _stageKeys,
        controller: _scrollController,
        foldedStages: _foldedStages,
        onFoldToggle: _toggleStageFold,
      ),
    );

    final title =
        tree.roots.isNotEmpty ? tree.roots.first.title : widget.trackId;

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
          Expanded(
            child: Stack(
              children: [
                list,
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildStickyBanner(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
