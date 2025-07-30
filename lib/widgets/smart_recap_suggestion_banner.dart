import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/recap_opportunity_detector.dart';
import '../services/smart_theory_recap_engine.dart';
import '../services/training_session_service.dart';
import '../widgets/theory_recap_dialog.dart';
import '../models/theory_mini_lesson_node.dart';

class SmartRecapSuggestionBanner extends StatefulWidget {
  const SmartRecapSuggestionBanner({super.key});

  @override
  State<SmartRecapSuggestionBanner> createState() =>
      _SmartRecapSuggestionBannerState();
}

class _SmartRecapSuggestionBannerState extends State<SmartRecapSuggestionBanner>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _visible = false;
  TheoryMiniLessonNode? _lesson;
  late AnimationController _anim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sessions = context.read<TrainingSessionService>();
    final busy = sessions.currentSession != null && !sessions.isCompleted;
    if (busy) {
      setState(() => _loading = false);
      return;
    }
    final detector = RecapOpportunityDetector.instance;
    final good = await detector.isGoodRecapMoment();
    if (!good) {
      setState(() => _loading = false);
      return;
    }
    final lesson = await SmartTheoryRecapEngine.instance.getNextRecap();
    if (lesson != null) {
      _lesson = lesson;
      _visible = true;
      _anim.forward();
      _timer = Timer(const Duration(seconds: 20), _dismiss);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _dismiss() async {
    if (!_visible) return;
    await _anim.reverse();
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _open() async {
    final lesson = _lesson;
    if (lesson == null) return;
    await showTheoryRecapDialog(
      context,
      lessonId: lesson.id,
      trigger: 'smartBanner',
    );
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_visible || _lesson == null) {
      return const SizedBox.shrink();
    }
    final accent = Theme.of(context).colorScheme.secondary;
    return FadeTransition(
      opacity: _anim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '💡 Подтверди знание?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: _dismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Быстрый повтор урока по твоей недавней ошибке',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _open,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Повторить сейчас'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
