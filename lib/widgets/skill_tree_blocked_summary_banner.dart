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

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<List<_LockedNodeData>> _load() async {
    final result = <_LockedNodeData>[];
    for (final node in widget.nodes) {
      final deps = await _linkService.getDependencies(node.id);
      final hint = deps.isNotEmpty ? deps.first.hint : '';
      result.add(_LockedNodeData(node: node, hint: hint));
    }
    return result;
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
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _BlockedNodeCard(
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

class _BlockedNodeCard extends StatelessWidget {
  final _LockedNodeData data;
  final VoidCallback onTap;

  const _BlockedNodeCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: InkWell(
          onTap: onTap,
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
    );
  }
}
