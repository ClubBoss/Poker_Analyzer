import 'package:flutter/material.dart';

import '../models/theory_pack_model.dart';
import '../services/theory_stage_completion_watcher.dart';
import '../services/theory_stage_progress_tracker.dart';
import '../theme/app_colors.dart';

/// Displays the full contents of a theory pack.
class TheoryPackReaderScreen extends StatefulWidget {
  static const route = '/theory_reader';
  final TheoryPackModel pack;
  final String stageId;
  const TheoryPackReaderScreen({
    super.key,
    required this.pack,
    required this.stageId,
  });

  @override
  State<TheoryPackReaderScreen> createState() => _TheoryPackReaderScreenState();
}

class _TheoryPackReaderScreenState extends State<TheoryPackReaderScreen> {
  late final ScrollController _controller;
  late final TheoryStageCompletionWatcher _watcher;
  late Future<bool> _completedFuture;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _watcher = TheoryStageCompletionWatcher();
    _completedFuture = TheoryStageProgressTracker.instance.isCompleted(
      widget.stageId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watcher.observe(
        widget.stageId,
        _controller,
        context: context,
        onCompleted: _onCompleted,
      );
    });
  }

  void _onCompleted() {
    setState(() {
      _completedFuture = TheoryStageProgressTracker.instance.isCompleted(
        widget.stageId,
      );
    });
  }

  @override
  void dispose() {
    _watcher.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSection(TheorySectionModel section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(section.text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _completedFuture,
      builder: (context, snapshot) {
        final completed = snapshot.data ?? false;
        return Scaffold(
          appBar: AppBar(title: Text(widget.pack.title)),
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              ListView.builder(
                controller: _controller,
                padding: const EdgeInsets.all(16),
                itemCount: widget.pack.sections.length,
                itemBuilder: (_, i) => _buildSection(widget.pack.sections[i]),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: completed ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✓ Completed',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
