import 'package:flutter/material.dart';

import '../models/learning_branch_node.dart';
import '../models/theory_lesson_node.dart';
import '../services/learning_graph_engine.dart';
import '../services/path_map_engine.dart';

/// Simple UI that walks through a learning path graph interactively.
class LearningPathRunnerScreen extends StatefulWidget {
  const LearningPathRunnerScreen({super.key});

  @override
  State<LearningPathRunnerScreen> createState() => _LearningPathRunnerScreenState();
}

class _LearningPathRunnerScreenState extends State<LearningPathRunnerScreen> {
  late Future<void> _initFuture;
  LearningPathNode? _current;

  @override
  void initState() {
    super.initState();
    _initFuture = LearningPathEngine.instance.initialize().then((_) {
      _current = LearningPathEngine.instance.getCurrentNode();
    });
  }

  void _refresh() {
    setState(() {
      _current = LearningPathEngine.instance.getCurrentNode();
    });
  }

  Future<void> _completeStage(StageNode node) async {
    await LearningPathEngine.instance.markStageCompleted(node.id);
    _refresh();
  }

  Future<void> _chooseBranch(LearningBranchNode node, String label) async {
    await LearningPathEngine.instance.applyBranchChoice(label);
    _refresh();
  }

  Widget _buildCurrent() {
    final node = _current;
    if (node == null) {
      return const Center(child: Text('Path completed'));
    }
    if (node is LearningBranchNode) {
      return _buildBranch(node);
    }
    if (node is TheoryLessonNode) {
      return _buildTheory(node);
    }
    if (node is StageNode) {
      return _buildStage(node);
    }
    return const SizedBox();
  }

  Widget _buildStage(StageNode node) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(node.id, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          const Text('Stage content placeholder'),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _completeStage(node),
              child: const Text('Complete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheory(TheoryLessonNode node) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            node.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(node.content),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                await LearningPathEngine.instance.markStageCompleted(node.id);
                _refresh();
              },
              child: const Text('Продолжить'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranch(LearningBranchNode node) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(node.prompt, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          for (final label in node.branches.keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => _chooseBranch(node, label),
                child: Text(label),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path Runner')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCurrent();
        },
      ),
    );
  }
}
