import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/skill_tree_node_model.dart';
import '../services/skill_tree_dependency_link_service.dart';

class SkillTreeBlockedSummaryBanner extends StatefulWidget {
  final List<SkillTreeNodeModel> nodes;
  final void Function(SkillTreeNodeModel node) onShowDetails;

  const SkillTreeBlockedSummaryBanner({
    super.key,
    required this.nodes,
    required this.onShowDetails,
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
        return SizedBox(
          height: 90,
          child: ListView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _BlockedNodeCard(
                    key: ValueKey(item.node.id),
                    data: item,
                    onTap: () => widget.onShowDetails(item.node),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BlockedNodeCard extends StatefulWidget {
  final _LockedNodeData data;
  final VoidCallback onTap;

  const _BlockedNodeCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  State<_BlockedNodeCard> createState() => _BlockedNodeCardState();
}

class _BlockedNodeCardState extends State<_BlockedNodeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return FadeTransition(
      opacity: _opacity,
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
    );
  }
}
