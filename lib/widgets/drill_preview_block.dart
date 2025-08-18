import 'package:flutter/material.dart';
import '../models/learning_path_block.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/booster_inventory_service.dart';
import '../services/training_session_launcher.dart';

/// Renders a preview card for a drill [LearningPathBlock].
class DrillPreviewBlock extends StatefulWidget {
  final LearningPathBlock block;
  final BoosterInventoryService inventory;
  final TrainingSessionLauncher launcher;

  DrillPreviewBlock({
    Key? key,
    required this.block,
    BoosterInventoryService? inventory,
    this.launcher = const TrainingSessionLauncher(),
  }) : inventory = inventory ?? BoosterInventoryService(),
       super(key: key);

  @override
  State<DrillPreviewBlock> createState() => _DrillPreviewBlockState();
}

class _DrillPreviewBlockState extends State<DrillPreviewBlock> {
  bool _loading = true;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.inventory.loadAll();
    final tpl = widget.inventory.getById(widget.block.lessonId);
    if (mounted) {
      setState(() {
        _pack = tpl;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final pack = _pack;
    if (pack == null) return;
    await widget.launcher.launch(pack);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pack == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.block.header,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (widget.block.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.block.content,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text(widget.block.ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}
