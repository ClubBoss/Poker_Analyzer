import 'package:flutter/material.dart';
import '../services/smart_resume_engine.dart';
import '../screens/v2/training_pack_play_screen.dart';

class ResumeTrainingCard extends StatefulWidget {
  const ResumeTrainingCard({super.key});

  @override
  State<ResumeTrainingCard> createState() => _ResumeTrainingCardState();
}

class _ResumeTrainingCardState extends State<ResumeTrainingCard> {
  UnfinishedPack? _pack;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SmartResumeEngine.instance.getRecentUnfinished(limit: 1);
    if (!mounted) return;
    setState(() => _pack = list.isNotEmpty ? list.first : null);
  }

  Future<void> _resume() async {
    final p = _pack;
    if (p == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrainingPackPlayScreen(template: p.template, original: p.template),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _pack;
    if (p == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: _resume,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '🔥 Continue training: ${p.template.name} · ${p.progressPercent}%',
          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
