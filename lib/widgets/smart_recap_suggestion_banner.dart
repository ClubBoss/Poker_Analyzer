import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/smart_recap_banner_controller.dart';
import '../services/recap_to_drill_launcher.dart';
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
  late SmartRecapBannerController _controller;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onChanged);
    _anim.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    _controller = context.read<SmartRecapBannerController>();
    _controller.addListener(_onChanged);
    _onChanged();
    _loading = false;
  }

  void _onChanged() {
    final shouldShow = _controller.shouldShowBanner();
    final lesson = _controller.getPendingLesson();
    if (shouldShow && lesson != null) {
      _lesson = lesson;
      if (!_visible) {
        _visible = true;
        _anim.forward();
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 20),
            () => _controller.dismiss(recordDismissal: true));
      }
    } else if (_visible) {
      _dismiss(false);
    }
    if (mounted) setState(() {});
  }

  Future<void> _dismiss([bool record = true]) async {
    if (!_visible) return;
    await _anim.reverse();
    await _controller.dismiss(recordDismissal: record);
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _open() async {
    final lesson = _lesson;
    if (lesson == null) return;
    final launcher = context.read<RecapToDrillLauncher>();
    await launcher.launch(lesson);
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
