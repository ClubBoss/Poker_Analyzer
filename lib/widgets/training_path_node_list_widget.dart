import 'package:flutter/material.dart';

import '../models/training_path_node.dart';
import '../services/training_path_node_definition_service.dart';
import '../services/training_path_progress_tracker_service.dart';
import '../screens/training_path_node_detail_screen.dart';
import 'training_node_summary_card.dart';

/// Displays the list of training path nodes with visual lock/unlock state.
///
/// Nodes that are unlocked can be tapped. Locked nodes are disabled. Completed
/// nodes show a checkmark.
class TrainingPathNodeListWidget extends StatefulWidget {
  const TrainingPathNodeListWidget({super.key});

  @override
  State<TrainingPathNodeListWidget> createState() =>
      _TrainingPathNodeListWidgetState();
}

class _TrainingPathNodeListWidgetState
    extends State<TrainingPathNodeListWidget> {
  final _definitions = const TrainingPathNodeDefinitionService();
  final _progress = const TrainingPathProgressTrackerService();

  late Future<_NodeStatusData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NodeStatusData> _load() async {
    final nodes = _definitions.getPath();
    final completedNodeIds = await _progress.getCompletedNodeIds();
    final unlockedNodeIds = await _progress.getUnlockedNodeIds();
    return _NodeStatusData(
      nodes: nodes,
      completedNodeIds: completedNodeIds,
      unlockedNodeIds: unlockedNodeIds,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NodeStatusData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            children: [
              for (final node in data.nodes)
                TrainingNodeSummaryCard(
                  node: node,
                  isUnlocked: data.unlockedNodeIds.contains(node.id),
                  isCompleted: data.completedNodeIds.contains(node.id),
                  onTap: data.unlockedNodeIds.contains(node.id)
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TrainingPathNodeDetailScreen(node: node),
                            ),
                          );
                          _refresh();
                        }
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NodeStatusData {
  final List<TrainingPathNode> nodes;
  final Set<String> completedNodeIds;
  final Set<String> unlockedNodeIds;

  const _NodeStatusData({
    required this.nodes,
    required this.completedNodeIds,
    required this.unlockedNodeIds,
  });
}
