import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/suggested_next_step_engine.dart';
import '../services/training_session_service.dart';
import '../models/v2/training_pack_template.dart';
import '../screens/v2/training_pack_play_screen.dart';

class ContinueTrainingButton extends StatefulWidget {
  const ContinueTrainingButton({super.key});

  @override
  State<ContinueTrainingButton> createState() => _ContinueTrainingButtonState();
}

class _ContinueTrainingButtonState extends State<ContinueTrainingButton> {
  TrainingPackTemplateV2? _next;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final engine = context.read<SuggestedNextStepEngine>();
    final tpl = await engine.suggestNext();
    if (mounted) {
      setState(() {
        _next = tpl;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    final engine = context.read<SuggestedNextStepEngine>();
    final tpl = await engine.suggestNext();
    if (!mounted) return;
    if (tpl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All training completed - well done!')),
      );
      setState(() => _starting = false);
      return;
    }
    final template = TrainingPackTemplate.fromJson(tpl.toJson());
    await context.read<TrainingSessionService>().startFromTemplate(template);
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TrainingPackPlayScreen(template: template, original: template),
        ),
      );
    }
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _start,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Column(
          children: [
            const Text('\uD83D\uDCC8 Continue Training'),
            if (_next != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Next: ${_next!.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
