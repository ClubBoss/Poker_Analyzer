import 'dart:io';

import 'package:flutter/material.dart';

import '../core/training/generation/yaml_writer.dart';
import '../services/learning_path_composer.dart';
import '../services/learning_path_store.dart';

/// Debug/admin screen to compose and publish learning paths.
class LearningPathComposerScreen extends StatefulWidget {
  const LearningPathComposerScreen({super.key});

  @override
  State<LearningPathComposerScreen> createState() =>
      _LearningPathComposerScreenState();
}

class _LearningPathComposerScreenState
    extends State<LearningPathComposerScreen> {
  final LearningPathComposer _composer = LearningPathComposer();
  Map<int, List<PackMeta>> _levels = const {};
  bool _busy = false;

  Future<void> _autoCompose() async {
    setState(() => _busy = true);
    // In this v1 implementation we compose with an empty pack list.
    final result = _composer.compose(const []);
    setState(() {
      _levels = result.assignments;
      _busy = false;
    });
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    final result = _composer.compose(const []);
    const writer = YamlWriter();
    const pathId = 'cash_path_v1';
    final tmpPath = 'assets/learning_paths/$pathId.yaml';
    await writer.write(result.path.toJson(), tmpPath);
    final yaml = await File(tmpPath).readAsString();
    await const LearningPathStore().publish(pathId, yaml);
    setState(() => _busy = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Path published')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _levels.entries.toList()..sort((a, b) => a.key - b.key);
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path Composer')),
      body: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: _busy ? null : _autoCompose,
                child: const Text('Auto-compose'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _busy ? null : _publish,
                child: const Text('Publish'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                for (final e in entries)
                  ListTile(
                    title: Text('Level ${e.key}'),
                    subtitle: Text(e.value.map((p) => p.id).join(', ')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
