import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../models/stage_type.dart';
import '../services/theory_pack_library_service.dart';
import '../ui/tools/theory_pack_quick_view.dart';
import '../utils/snackbar_util.dart';

/// Lightweight preview showing key details of a learning path.
class SmartPathPreviewScreen extends StatelessWidget {
  final LearningPathTemplateV2 path;
  const SmartPathPreviewScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final groups = <StageType, List<LearningPathStageModel>>{};
    for (final stage in path.stages) {
      groups.putIfAbsent(stage.type, () => []).add(stage);
    }
    return Scaffold(
      appBar: AppBar(title: Text(path.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (path.description.isNotEmpty)
            Text(
              path.description,
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 12),
          Text(
            '${path.stages.length} стадий',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          for (final type in StageType.values)
            if (groups[type]?.isNotEmpty ?? false)
              _buildGroup(context, type, groups[type]!),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    StageType type,
    List<LearningPathStageModel> stages,
  ) {
    final color = _colorFor(type, context);
    final icon = _iconFor(type);
    final label = _labelFor(type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final stage in stages)
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(stage.title),
            subtitle: Text(stage.packId),
            trailing: _buildPreviewButton(context, stage),
            tileColor:
                stage.type == StageType.theory ? color.withOpacity(0.1) : null,
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget? _buildPreviewButton(
    BuildContext context,
    LearningPathStageModel stage,
  ) {
    if (stage.type != StageType.theory || stage.packId.isEmpty) return null;
    return IconButton(
      icon: const Icon(Icons.visibility),
      onPressed: () async {
        final pack = TheoryPackLibraryService.instance.getById(stage.packId);
        if (pack != null) {
          await TheoryPackQuickView.launch(context, pack);
        } else {
          SnackbarUtil.showMessage(context, 'Pack not found: ${stage.packId}');
        }
      },
    );
  }

  IconData _iconFor(StageType type) {
    switch (type) {
      case StageType.theory:
        return Icons.menu_book;
      case StageType.booster:
        return Icons.bolt;
      case StageType.practice:
      default:
        return Icons.fitness_center;
    }
  }

  Color _colorFor(StageType type, BuildContext context) {
    switch (type) {
      case StageType.theory:
        return Colors.blue;
      case StageType.booster:
        return Colors.orange;
      case StageType.practice:
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  String _labelFor(StageType type) {
    switch (type) {
      case StageType.theory:
        return 'Теория';
      case StageType.booster:
        return 'Booster';
      case StageType.practice:
      default:
        return 'Практика';
    }
  }
}

