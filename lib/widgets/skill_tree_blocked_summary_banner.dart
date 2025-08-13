import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_dependency_link_service.dart';

class SkillTreeBlockedSummaryBanner extends StatefulWidget {
  final List<SkillTreeNodeModel> nodes;
  final void Function(SkillTreeNodeModel node) onShowDetails;
  final int unlockedCount;
  final int totalCount;

  const SkillTreeBlockedSummaryBanner({
    super.key,
    required this.nodes,
    required this.onShowDetails,
    required this.unlockedCount,
    required this.totalCount,
  });

  @override
  State<SkillTreeBlockedSummaryBanner> createState() =>
      _SkillTreeBlockedSummaryBannerState();
}

class _LockedNodeData {
  final SkillTreeNodeModel node;
  final String hint;

  _LockedNodeData({required this.node, required this.hint});
}

class _SkillTreeBlockedSummaryBannerState
    extends State<SkillTreeBlockedSummaryBanner> {
  final _linkService = SkillTreeDependencyLinkService();
  late Future<List<_LockedNodeData>> _dataFuture;
  final _scrollController = ScrollController();
  Set<String> _prevIds = {};
  Set<String> _newlyAddedIds = {};
  static const double _itemWidth = 208;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
    _prevIds = widget.nodes.map((e) => e.id).toSet();
  }

  @override
  void didUpdateWidget(covariant SkillTreeBlockedSummaryBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIds = widget.nodes.map((e) => e.id).toSet();
    if (!setEquals(newIds, _prevIds)) {
      final added = newIds.difference(_prevIds);
      setState(() {
        _dataFuture = _load();
        _prevIds = newIds;
        _newlyAddedIds = added;
      });
      if (added.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          final index = widget.nodes.indexWhere((n) => added.contains(n.id));
          if (_scrollController.hasClients && index >= 0) {
            _scrollController.animateTo(
              index * _itemWidth,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  Future<List<_LockedNodeData>> _load() async {
    final result = <_LockedNodeData>[];
    for (final node in widget.nodes) {
      try {
        final deps = await _linkService.getDependencies(node.id);
        final hint = deps.isNotEmpty ? deps.first.hint : '';
        result.add(_LockedNodeData(node: node, hint: hint));
      } catch (_) {
        result.add(_LockedNodeData(node: node, hint: ''));
      }
    }
    return result;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LockedNodeData>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data!;
        final progressText =
            '${widget.unlockedCount} of ${widget.totalCount} unlocked';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  progressText,
                  key: ValueKey(progressText),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 90,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  _LockedCountBadge(count: items.length),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _BlockedNodeCard(
                        key: ValueKey(item.node.id),
                        data: item,
                        onTap: () => widget.onShowDetails(item.node),
                        highlight: _newlyAddedIds.contains(item.node.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LockedCountBadge extends StatelessWidget {
  final int count;

  const _LockedCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Locked steps',
      child: SizedBox(
        width: 40,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: CircleAvatar(
              key: ValueKey(count),
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.error,
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedNodeCard extends StatefulWidget {
  final _LockedNodeData data;
  final VoidCallback onTap;
  final bool highlight;

  const _BlockedNodeCard({
    super.key,
    required this.data,
    required this.onTap,
    this.highlight = false,
  });

  @override
  State<_BlockedNodeCard> createState() => _BlockedNodeCardState();
}

class _BlockedNodeCardState extends State<_BlockedNodeCard>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _opacity;
  AnimationController? _pulseController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    if (widget.highlight) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _scale = Tween<double>(begin: 1, end: 1.05).animate(
          CurvedAnimation(parent: _pulseController!, curve: Curves.easeOut));
      _pulseController!.forward().then((_) => _pulseController!.reverse());
    } else {
      _scale = const AlwaysStoppedAnimation(1);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 200,
          child: Card(
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.node.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.hint.isNotEmpty
                          ? data.hint
                          : 'No unlock requirements available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
