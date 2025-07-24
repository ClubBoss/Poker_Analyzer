import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../services/learning_path_registry_service.dart';
import '../widgets/learning_path_stage_widget.dart';

/// Simple preview page for a learning path template.
class PathPreviewScreen extends StatefulWidget {
  final String pathId;
  const PathPreviewScreen({super.key, required this.pathId});

  @override
  State<PathPreviewScreen> createState() => _PathPreviewScreenState();
}

class _PathPreviewScreenState extends State<PathPreviewScreen> {
  LearningPathTemplateV2? _template;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final registry = LearningPathRegistryService.instance;
    await registry.loadAll();
    final tpl = registry.findById(widget.pathId);
    if (mounted) {
      setState(() {
        _template = tpl;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpl = _template;
    return Scaffold(
      appBar: AppBar(title: Text(tpl?.title ?? 'Path')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tpl == null
              ? const Center(child: Text('Path not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (tpl.description.isNotEmpty)
                      Text(
                        tpl.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '${tpl.stages.length} стадий',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    for (final stage in tpl.stages)
                      LearningPathStageWidget(
                        stage: stage,
                        progress: 0.0,
                        handsPlayed: 0,
                        unlocked: true,
                        onPressed: () {},
                      ),
                  ],
                ),
    );
  }
}
