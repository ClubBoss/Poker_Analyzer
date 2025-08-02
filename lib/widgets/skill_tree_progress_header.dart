import 'package:flutter/material.dart';

import '../models/skill_tree.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_track_progress_service.dart';
import '../route_observer.dart';
import 'stage_progress_bar.dart';

/// Displays current stage and overall progress for a skill tree track.
class SkillTreeProgressHeader extends StatefulWidget {
  final String trackId;
  final SkillTreeLibraryService library;
  final SkillTreeTrackProgressService progressService;

  const SkillTreeProgressHeader({
    super.key,
    required this.trackId,
    SkillTreeLibraryService? library,
    SkillTreeTrackProgressService? progressService,
  }) : library = library ?? SkillTreeLibraryService.instance,
       progressService = progressService ?? SkillTreeTrackProgressService();

  @override
  State<SkillTreeProgressHeader> createState() =>
      _SkillTreeProgressHeaderState();
}

class _SkillTreeProgressHeaderState extends State<SkillTreeProgressHeader>
    with RouteAware {
  SkillTree? _track;
  Set<String> _completed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _load();
  }

  Future<void> _load() async {
    await widget.library.reload();
    final res = widget.library.getTrack(widget.trackId);
    final tree = res?.tree;
    if (tree == null) {
      setState(() => _loading = false);
      return;
    }
    final completed = await widget.progressService.getCompletedNodeIds(
      widget.trackId,
    );
    if (!mounted) return;
    setState(() {
      _track = tree;
      _completed = completed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final tree = _track;
    if (tree == null) return const SizedBox.shrink();
    final total = tree.nodes.values
        .where((n) => (n as dynamic).isOptional != true)
        .length;
    final done = tree.nodes.values
        .where(
          (n) => (n as dynamic).isOptional != true && _completed.contains(n.id),
        )
        .length;
    final overallProgress = total > 0 ? done / total : 0.0;

    final accent = Theme.of(context).colorScheme.secondary;
    final pct = (overallProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          StageProgressBar(tree: tree, completedNodeIds: _completed),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '$pct%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (overallProgress >= 1.0)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('🎉', style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
