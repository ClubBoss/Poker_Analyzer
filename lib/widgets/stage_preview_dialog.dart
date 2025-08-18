import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../services/pack_library_service.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Dialog showing brief information about a learning path stage.
class StagePreviewDialog extends StatefulWidget {
  final LearningPathStageModel stage;
  const StagePreviewDialog({super.key, required this.stage});

  @override
  State<StagePreviewDialog> createState() => _StagePreviewDialogState();
}

class _StagePreviewDialogState extends State<StagePreviewDialog> {
  TrainingPackTemplateV2? _pack;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PackLibraryService.instance.getById(widget.stage.packId);
    if (mounted) {
      setState(() {
        _pack = p;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = _pack;
    final estMinutes = pack == null ? null : (pack.spotCount / 2).ceil();
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(widget.stage.title),
      content: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.stage.description.isNotEmpty)
                  Text(
                    widget.stage.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (pack != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Spots: ${pack.spotCount}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (estMinutes != null)
                    Text(
                      'Estimated time: ${estMinutes}m',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
                if (widget.stage.objectives.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final o in widget.stage.objectives)
                        Chip(label: Text(o)),
                    ],
                  ),
                ],
                if (widget.stage.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final t in widget.stage.tags) Chip(label: Text(t)),
                    ],
                  ),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Начать тренировку'),
        ),
      ],
    );
  }
}
