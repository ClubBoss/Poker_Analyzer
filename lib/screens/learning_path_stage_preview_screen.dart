import 'package:flutter/material.dart';
import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../services/pack_library_service.dart';
import '../services/theory_pack_library_service.dart';
import '../services/training_progress_service.dart';
import '../services/learning_path_stage_launcher.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/theory_pack_model.dart';
import '../screens/theory_pack_reader_screen.dart';
import '../widgets/stage_share_button.dart';

/// Simple preview page for a learning path stage.
class LearningPathStagePreviewScreen extends StatefulWidget {
  final LearningPathTemplateV2 path;
  final LearningPathStageModel stage;
  const LearningPathStagePreviewScreen({
    super.key,
    required this.path,
    required this.stage,
  });

  @override
  State<LearningPathStagePreviewScreen> createState() =>
      _LearningPathStagePreviewScreenState();
}

class _LearningPathStagePreviewScreenState
    extends State<LearningPathStagePreviewScreen> {
  TrainingPackTemplateV2? _pack;
  TheoryPackModel? _theory;
  double _progress = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pack = await PackLibraryService.instance.getById(widget.stage.packId);
    final prog =
        await TrainingProgressService.instance.getProgress(widget.stage.packId);
    TheoryPackModel? theory;
    final theoryId = widget.stage.theoryPackId;
    if (theoryId != null) {
      await TheoryPackLibraryService.instance.loadAll();
      theory = TheoryPackLibraryService.instance.getById(theoryId);
    }
    if (mounted) {
      setState(() {
        _pack = pack;
        _theory = theory;
        _progress = prog;
        _loading = false;
      });
    }
  }

  Future<void> _openTheory() async {
    final pack = _theory;
    if (pack == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryPackReaderScreen(pack: pack, stageId: widget.stage.id),
      ),
    );
  }

  Future<void> _start() async {
    await const LearningPathStageLauncher().launch(context, widget.stage);
  }

  @override
  Widget build(BuildContext context) {
    final pack = _pack;
    final theory = _theory;
    final estMinutes = pack == null ? null : (pack.spotCount / 2).ceil();
    final progressPct = (_progress.clamp(0.0, 1.0) * 100).round();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stage.title),
        actions: [StageShareButton(path: widget.path, stage: widget.stage)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.stage.description.isNotEmpty)
                  Text(
                    widget.stage.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress.clamp(0.0, 1.0)),
                const SizedBox(height: 4),
                Text(
                  '$progressPct% пройдено',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (pack != null) ...[
                  const SizedBox(height: 8),
                  Text('Spots: ${pack.spotCount}',
                      style: const TextStyle(color: Colors.white70)),
                  if (estMinutes != null)
                    Text('Estimated time: ${estMinutes}m',
                        style: const TextStyle(color: Colors.white70)),
                ],
                if (widget.stage.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final t in widget.stage.tags) Chip(label: Text(t)),
                    ],
                  ),
                ],
                if (theory != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '📚 ${theory.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${theory.sections.length} разделов',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: _openTheory,
                    child: const Text('Открыть теорию'),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _start,
                    child: const Text('Начать'),
                  ),
                ),
              ],
            ),
    );
  }
}

