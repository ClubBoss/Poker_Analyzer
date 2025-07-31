import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/learning_path_block.dart';
import '../widgets/injected_theory_block_renderer.dart';
import '../services/injection_block_assembler.dart';
import '../services/smart_theory_injection_engine.dart';

import '../models/learning_branch_node.dart';
import '../models/theory_lesson_node.dart';
import '../services/learning_graph_engine.dart';
import '../services/path_map_engine.dart';
import '../services/theory_content_service.dart';

/// Simple UI that walks through a learning path graph interactively.
class LearningPathRunnerScreen extends StatefulWidget {
  const LearningPathRunnerScreen({super.key});

  @override
  State<LearningPathRunnerScreen> createState() => _LearningPathRunnerScreenState();
}

class _LearningPathRunnerScreenState extends State<LearningPathRunnerScreen> {
  late Future<void> _initFuture;
  LearningPathNode? _current;
  LearningPathBlock? _injectedBlock;
  final Set<String> _shownStages = <String>{};

  @override
  void initState() {
    super.initState();
    _initFuture = LearningPathEngine.instance.initialize().then((_) {
      _current = LearningPathEngine.instance.getCurrentNode();
      final node = _current;
      if (node is StageNode) {
        _prepareInjection(node);
      }
    });
  }

  void _refresh() {
    final node = LearningPathEngine.instance.getCurrentNode();
    if (node is StageNode) {
      _prepareInjection(node);
    } else {
      _injectedBlock = null;
    }
    setState(() {
      _current = node;
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

  Future<void> _prepareInjection(StageNode node) async {
    if (_shownStages.contains(node.id)) return;
    _shownStages.add(node.id);
    final candidate =
        await const SmartTheoryInjectionEngine().getInjectionCandidate(node.id);
    if (candidate == null) return;
    final block = const InjectionBlockAssembler().build(candidate, node.id);
    if (!mounted) return;
    setState(() => _injectedBlock = block);
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
          if (_injectedBlock != null)
            InjectedTheoryBlockRenderer(block: _injectedBlock!),
          if (_injectedBlock != null) const SizedBox(height: 16),
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
    final title = node.resolvedTitle;
    final content = node.resolvedContent;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Markdown(
              data: content,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
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
