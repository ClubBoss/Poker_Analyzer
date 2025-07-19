import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/training_pack_template.dart';
import '../services/smart_review_service.dart';
import '../services/template_storage_service.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';
import 'v2/training_pack_play_screen.dart';

class MistakeReviewScreen extends StatefulWidget {
  final TrainingPackTemplate? template;
  const MistakeReviewScreen({super.key, this.template});

  @override
  State<MistakeReviewScreen> createState() => _MistakeReviewScreenState();
}

class _MistakeReviewScreenState extends State<MistakeReviewScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.template != null) {
      setState(() => _loading = false);
      return;
    }
    final templates = context.read<TemplateStorageService>();
    final spots = await SmartReviewService.instance.getMistakeSpots(templates);
    if (!mounted) return;
    if (spots.isNotEmpty) {
      final tpl = TrainingPackTemplate(
        id: const Uuid().v4(),
        name: 'Повтор ошибок',
        createdAt: DateTime.now(),
        spots: spots,
      );
      await context.read<TrainingSessionService>().startSession(tpl);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
        );
      }
      if (mounted) {
        final clear = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: const Text('Очистить ошибки?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Нет'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Да'),
              ),
            ],
          ),
        );
        if (clear == true) {
          await SmartReviewService.instance.clearMistakes();
        }
      }
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpl = widget.template;
    if (tpl != null) {
      return TrainingPackPlayScreen(template: tpl, original: tpl);
    }
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(child: Text('Нет ошибок для повторения')),
    );
  }
}
