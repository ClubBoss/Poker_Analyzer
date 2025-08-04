import 'package:flutter/material.dart';

import '../models/training_path_node.dart';
import '../models/v2/training_pack_template.dart';
import '../services/pack_library_template_loader.dart';
import '../services/training_path_breadcrumb_service.dart';
import '../services/training_path_node_launcher_service.dart';
import '../services/training_path_progress_tracker_service.dart';
import '../widgets/training_pack_template_card.dart';

class TrainingPathNodeDetailScreen extends StatefulWidget {
  final TrainingPathNode node;
  const TrainingPathNodeDetailScreen({super.key, required this.node});

  @override
  State<TrainingPathNodeDetailScreen> createState() =>
      _TrainingPathNodeDetailScreenState();
}

class _TrainingPathNodeDetailScreenState
    extends State<TrainingPathNodeDetailScreen> {
  final _tracker = const TrainingPathProgressTrackerService();
  final _launcher = const TrainingPathNodeLauncherService();
  final _breadcrumbService = const TrainingPathBreadcrumbService();

  late Future<_NodeDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NodeDetailData> _load() async {
    final templates = <TrainingPackTemplate>[];
    for (final id in widget.node.packIds) {
      final tpl = await PackLibraryTemplateLoader.load(id);
      if (tpl != null) templates.add(tpl);
    }
    final completed = await _tracker.getCompletedNodeIds();
    final unlocked = await _tracker.getUnlockedNodeIds();
    final isCompleted = completed.contains(widget.node.id);
    final isUnlocked = unlocked.contains(widget.node.id);
    final breadcrumb = _breadcrumbService.getBreadcrumb(widget.node);
    return _NodeDetailData(
      templates: templates,
      isCompleted: isCompleted,
      isUnlocked: isUnlocked,
      breadcrumb: breadcrumb,
      unlockedNodeIds: unlocked,
    );
  }

  Future<void> _startTraining() async {
    await _launcher.launchNode(context, widget.node);
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NodeDetailData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(widget.node.title)),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildBreadcrumb(data!),
                    const SizedBox(height: 16),
                    _buildStatusChip(data),
                    const SizedBox(height: 16),
                    if (data.templates.isNotEmpty) ...[
                      const Text('Паки',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      for (final tpl in data.templates)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TrainingPackTemplateCard(template: tpl),
                        ),
                    ] else
                      const Text('No training packs found'),
                  ],
                ),
          bottomNavigationBar: snapshot.connectionState !=
                      ConnectionState.done ||
                  !(data?.isUnlocked ?? false)
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _startTraining,
                      child: const Text('Start Training'),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBreadcrumb(_NodeDetailData data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final node in data.breadcrumb)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(node.title),
                onPressed: node.id == widget.node.id ||
                        !data.unlockedNodeIds.contains(node.id)
                    ? null
                    : () => _openNode(node),
                backgroundColor: node.id == widget.node.id
                    ? Colors.blue.shade200
                    : data.unlockedNodeIds.contains(node.id)
                        ? null
                        : Colors.grey.shade300,
              ),
            ),
        ],
      ),
    );
  }

  void _openNode(TrainingPathNode node) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingPathNodeDetailScreen(node: node),
      ),
    );
  }

  Widget _buildStatusChip(_NodeDetailData data) {
    String label;
    Color color;
    if (data.isCompleted) {
      label = 'Completed';
      color = Colors.green;
    } else if (data.isUnlocked) {
      label = 'Unlocked';
      color = Colors.blueGrey;
    } else {
      label = 'Locked';
      color = Colors.grey;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label),
        backgroundColor: color,
      ),
    );
  }
}

class _NodeDetailData {
  final List<TrainingPackTemplate> templates;
  final bool isCompleted;
  final bool isUnlocked;
  final List<TrainingPathNode> breadcrumb;
  final Set<String> unlockedNodeIds;

  const _NodeDetailData({
    required this.templates,
    required this.isCompleted,
    required this.isUnlocked,
    required this.breadcrumb,
    required this.unlockedNodeIds,
  });
}

