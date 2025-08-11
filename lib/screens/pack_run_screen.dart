import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/learning_path_controller.dart';
import '../models/learning_path_stage_model.dart';
import '../services/pack_registry_service.dart';
import '../services/missing_pack_resolver.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'v2/training_pack_play_screen.dart';

/// Screen allowing a user to run a stage's training pack.
class PackRunScreen extends StatefulWidget {
  final LearningPathController controller;
  final LearningPathStageModel stage;
  const PackRunScreen({super.key, required this.controller, required this.stage});

  @override
  State<PackRunScreen> createState() => _PackRunScreenState();
}

class _PackRunScreenState extends State<PackRunScreen> {
  TrainingPackTemplateV2? _pack;
  bool _loading = true;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    widget.controller.startStage(widget.stage.id);
    _load();
  }

  Future<void> _load() async {
    final pack = await PackRegistryService.instance.getById(widget.stage.packId);
    setState(() {
      _pack = pack;
      _loading = false;
    });
  }

  Future<void> _generate() async {
    setState(() => _resolving = true);
    final resolver = MissingPackResolver(
      generator: (id, {presetId}) => Future.error('autogen not configured'),
    );
    final pack = await resolver.resolve(widget.stage);
    setState(() {
      _pack = pack;
      _resolving = false;
    });
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TrainingPackPlayScreen(template: tpl, original: tpl),
    ));
    widget.controller.recordHand(correct: true);
    setState(() {});
  }

  void _openTheory() {
    final links = <dynamic>{};
    for (final s in _pack?.spots ?? const []) {
      final list = s.meta['theoryLinks'];
      if (list is List) links.addAll(list);
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          for (final l in links)
            ListTile(
              title: Text(l.toString()),
              onTap: () {
                Clipboard.setData(ClipboardData(text: l.toString()));
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.stageProgress(widget.stage.id);
    final requiredHands = widget.stage.requiredHands;
    final requiredAcc = widget.stage.requiredAccuracy * 100;
    final unlocked = widget.controller.isStageUnlocked(widget.stage.id);
    final hasTheory = (_pack?.spots ?? const [])
        .any((s) => (s.meta['theoryLinks'] as List?)?.isNotEmpty == true);
    return Scaffold(
      appBar: AppBar(title: Text(widget.stage.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      'Hands: ${progress.handsPlayed}/$requiredHands'),
                  Text(
                      'Accuracy: ${(progress.accuracy * 100).toStringAsFixed(0)}% / ${requiredAcc.toStringAsFixed(0)}%'),
                  const SizedBox(height: 20),
                  if (_pack == null)
                    ElevatedButton(
                      onPressed: _resolving ? null : _generate,
                      child: _resolving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Generate Missing'),
                    )
                  else
                    Tooltip(
                      message: unlocked ? '' : 'Stage locked',
                      child: ElevatedButton(
                        onPressed: unlocked ? _start : null,
                        child: const Text('Start'),
                      ),
                    ),
                  if (hasTheory)
                    TextButton(
                      onPressed: _openTheory,
                      child: const Text('Open theory'),
                    ),
                  if (widget.controller.stageProgress(widget.stage.id).completed)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Stage complete!'),
                    ),
                ],
              ),
            ),
    );
  }
}

