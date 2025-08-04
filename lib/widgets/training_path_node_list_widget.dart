import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../models/training_path_node.dart';
import '../services/training_path_node_definition_service.dart';
import '../services/training_path_node_launcher_service.dart';
import '../services/training_path_progress_tracker_service.dart';

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
  final _launcher = const TrainingPathNodeLauncherService();

  late Future<_NodeStatusData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NodeStatusData> _load() async {
    final nodes = _definitions.getPath();
    final completed = await _progress.getCompletedNodeIds();
    final unlocked = await _progress.getUnlockedNodeIds();
    return _NodeStatusData(
      nodes: nodes,
      completed: completed,
      unlocked: unlocked,
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
              for (final node in data.nodes) _buildTile(node, data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile(TrainingPathNode node, _NodeStatusData data) {
    final isCompleted = data.completed.contains(node.id);
    final isUnlocked = data.unlocked.contains(node.id);
    final icon = isCompleted
        ? const Icon(Icons.check, color: Colors.green)
        : isUnlocked
            ? const Icon(Icons.lock_open)
            : const Icon(Icons.lock);
    return ListTile(
      leading: icon,
      title: Text(node.title),
      enabled: isUnlocked,
      onTap: isUnlocked ? () => _launcher.launchNode(context, node) : null,
    );
  }
}

class _NodeStatusData {
  final List<TrainingPathNode> nodes;
  final Set<String> completed;
  final Set<String> unlocked;

  const _NodeStatusData({
    required this.nodes,
    required this.completed,
    required this.unlocked,
  });
}
