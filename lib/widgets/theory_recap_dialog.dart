import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/recall_analytics_service.dart';
import '../theme/app_colors.dart';

class TheoryRecapDialog extends StatefulWidget {
  final String? lessonId;
  final List<String>? tags;
  final String trigger;
  final Duration autoCloseDelay;

  const TheoryRecapDialog({
    super.key,
    this.lessonId,
    this.tags,
    required this.trigger,
    this.autoCloseDelay = const Duration(seconds: 3),
  });

  @override
  State<TheoryRecapDialog> createState() => _TheoryRecapDialogState();
}

class _TheoryRecapDialogState extends State<TheoryRecapDialog> {
  final ScrollController _scroll = ScrollController();
  TheoryMiniLessonNode? _lesson;
  bool _loading = true;
  bool _autoScheduled = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_handleScroll);
  }

  Future<void> _load() async {
    await MiniLessonLibraryService.instance.loadAll();
    if (widget.lessonId != null) {
      _lesson = MiniLessonLibraryService.instance.getById(widget.lessonId!);
    }
    if (_lesson == null && widget.tags != null && widget.tags!.isNotEmpty) {
      final list = MiniLessonLibraryService.instance.findByTags(widget.tags!);
      if (list.isNotEmpty) _lesson = list.first;
    }
    RecallAnalyticsService.instance.recapOpened(
      trigger: widget.trigger,
      lessonId: _lesson?.id ?? widget.lessonId,
      tags: widget.tags,
    );
    if (mounted) setState(() => _loading = false);
  }

  void _handleScroll() {
    if (_lesson == null || _autoScheduled) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent &&
        _scroll.position.atEdge) {
      _autoScheduled = true;
      Future.delayed(widget.autoCloseDelay, () {
        if (mounted && !_closed) _close(true);
      });
    }
  }

  void _close([bool? result]) {
    if (_closed) return;
    _closed = true;
    RecallAnalyticsService.instance.recapClosed();
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_lesson == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No theory found', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Markdown(
                controller: _scroll,
                data: _lesson!.resolvedContent,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: const TextStyle(color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _close(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent),
                      ),
                      child: const Text('Remind me later'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _close(true),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showTheoryRecapDialog(
  BuildContext context, {
  String? lessonId,
  List<String>? tags,
  required String trigger,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Recap',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) =>
        TheoryRecapDialog(lessonId: lessonId, tags: tags, trigger: trigger),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}
