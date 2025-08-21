import 'package:flutter/material.dart';
import '../services/skill_tree_settings_service.dart';

import '../models/skill_tree_dependency_link.dart';
import '../services/skill_tree_dependency_link_service.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_node_progress_tracker.dart';
import '../services/skill_tree_unlock_evaluator.dart';

/// Widget that shows why a skill tree node is blocked.
///
/// It lists the prerequisite chain and unlock hint for each locked
/// dependency returned by [SkillTreeDependencyLinkService]. The widget is
/// designed to fit into small spaces such as modals or tooltips.
class SkillTreeNodeBlockReasonWidget extends StatelessWidget {
  final String nodeId;
  final SkillTreeDependencyLinkService _linkService;
  final SkillTreeLibraryService _library;
  final SkillTreeNodeProgressTracker _progress;
  final SkillTreeUnlockEvaluator _unlockEval;
  final void Function(String nodeId)? onJumpToNode;

  SkillTreeNodeBlockReasonWidget({
    super.key,
    required this.nodeId,
    this.onJumpToNode,
    SkillTreeDependencyLinkService? linkService,
    SkillTreeLibraryService? library,
    SkillTreeNodeProgressTracker? progress,
    SkillTreeUnlockEvaluator? unlockEvaluator,
  })  : _linkService = linkService ?? SkillTreeDependencyLinkService(),
        _library = library ?? SkillTreeLibraryService.instance,
        _progress = progress ?? SkillTreeNodeProgressTracker.instance,
        _unlockEval = unlockEvaluator ??
            SkillTreeUnlockEvaluator(
              progress: progress ?? SkillTreeNodeProgressTracker.instance,
            );

  String _titleForNode(String id) {
    for (final n in _library.getAllNodes()) {
      if (n.id == id) return n.title;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SkillTreeDependencyLink>>(
      future: _linkService.getDependencies(nodeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final deps = snapshot.data!;
        final completed = _progress.completedNodeIds.value;
        final unlocked = <String>{};
        for (final res in _library.getAllTracks()) {
          unlocked.addAll(
            _unlockEval.getUnlockedNodes(res.tree).map((n) => n.id),
          );
        }
        if (deps.isEmpty) {
          return const Text(
            'No unlock requirements available',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final link in deps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _DependencyItem(
                  title: _titleForNode(link.nodeId),
                  prereqs: [
                    for (final id in link.prerequisites)
                      _Prereq(
                        id: id,
                        title: _titleForNode(id),
                        status: completed.contains(id)
                            ? _PrereqStatus.completed
                            : unlocked.contains(id)
                                ? _PrereqStatus.unlocked
                                : _PrereqStatus.locked,
                      ),
                  ],
                  hint: link.hint,
                  onJumpToNode: onJumpToNode,
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _PrereqStatus { completed, unlocked, locked }

class _Prereq {
  final String id;
  final String title;
  final _PrereqStatus status;

  _Prereq({required this.id, required this.title, required this.status});
}

class _DependencyItem extends StatefulWidget {
  final String title;
  final List<_Prereq> prereqs;
  final String hint;
  final void Function(String nodeId)? onJumpToNode;

  const _DependencyItem({
    required this.title,
    required this.prereqs,
    required this.hint,
    this.onJumpToNode,
  });

  @override
  State<_DependencyItem> createState() => _DependencyItemState();
}

class _DependencyItemState extends State<_DependencyItem> {
  bool _hideCompleted = false;
  late VoidCallback _notifierListener;

  @override
  void initState() {
    super.initState();
    final service = SkillTreeSettingsService.instance;
    _hideCompleted = service.hideCompletedPrereqs.value;
    _notifierListener = () =>
        setState(() => _hideCompleted = service.hideCompletedPrereqs.value);
    service.hideCompletedPrereqs.addListener(_notifierListener);
    service.load();
  }

  @override
  void dispose() {
    SkillTreeSettingsService.instance.hideCompletedPrereqs.removeListener(
      _notifierListener,
    );
    super.dispose();
  }

  Future<void> _toggleHideCompleted(bool value) async {
    await SkillTreeSettingsService.instance.setHideCompletedPrereqs(value);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.prereqs.length;
    final done =
        widget.prereqs.where((p) => p.status == _PrereqStatus.completed).length;
    final visiblePrereqs = _hideCompleted
        ? widget.prereqs
            .where((p) => p.status != _PrereqStatus.completed)
            .toList()
        : widget.prereqs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (widget.prereqs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '✅ $done of $total prerequisites complete',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        if (widget.prereqs.isNotEmpty)
          SwitchListTile(
            value: _hideCompleted,
            onChanged: _toggleHideCompleted,
            title: const Text(
              'Hide completed prerequisites',
              style: TextStyle(fontSize: 12),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
        if (visiblePrereqs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < visiblePrereqs.length; i++) ...[
                  _buildPrereqChip(context, visiblePrereqs[i]),
                  if (i != visiblePrereqs.length - 1)
                    const Icon(Icons.arrow_right, size: 14, color: Colors.grey),
                ],
              ],
            ),
          ),
        if (widget.hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.hint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildPrereqChip(BuildContext context, _Prereq prereq) {
    IconData icon;
    Color color;
    String tooltip;
    switch (prereq.status) {
      case _PrereqStatus.completed:
        icon = Icons.check;
        color = Colors.green;
        tooltip = 'Completed';
        break;
      case _PrereqStatus.unlocked:
        icon = Icons.circle;
        color = Colors.amber;
        tooltip = 'Unlocked';
        break;
      case _PrereqStatus.locked:
        icon = Icons.lock;
        color = Colors.grey;
        tooltip = 'Locked';
        break;
    }
    final chip = Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(prereq.title, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return GestureDetector(
      onTap: widget.onJumpToNode != null
          ? () => widget.onJumpToNode!(prereq.id)
          : null,
      child: Tooltip(message: tooltip, child: chip),
    );
  }
}
