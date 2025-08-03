import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../models/training_type.dart';
import '../services/pack_favorite_service.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/training_session_launcher.dart';
import '../services/training_progress_logger.dart';
import '../services/theory_lesson_completion_logger.dart';
import '../services/training_progress_tracker_service.dart';

class PackCard extends StatefulWidget {
  final TrainingPackTemplateV2 template;
  final VoidCallback onTap;
  const PackCard({super.key, required this.template, required this.onTap});

  @override
  State<PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<PackCard> with SingleTickerProviderStateMixin {
  late bool _favorite;
  bool _theoryCompleted = false;
  int _completed = 0;
  late int _total;

  bool _showReward = false;
  late final AnimationController _rewardController;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _favorite = PackFavoriteService.instance.isFavorite(widget.template.id);
    _total =
        widget.template.spots.isNotEmpty ? widget.template.spots.length : widget.template.spotCount;
    _rewardController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadProgress();
    TrainingProgressTrackerService.instance.addListener(_loadProgress);
    _checkTheory();
  }

  @override
  void dispose() {
    TrainingProgressTrackerService.instance.removeListener(_loadProgress);
    _rewardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final ids = await TrainingProgressTrackerService.instance
        .getCompletedSpotIds(widget.template.id);
    if (mounted) {
      setState(() => _completed = ids.length);
      _maybeShowReward();
    }
  }

  Future<void> _toggleFavorite() async {
    await PackFavoriteService.instance.toggleFavorite(widget.template.id);
    if (mounted) {
      setState(() => _favorite = !_favorite);
    }
  }

  String? _linkedLessonId() {
    final metaId = widget.template.meta['lessonId'] as String?;
    if (metaId != null && metaId.isNotEmpty) return metaId;
    if (widget.template.id == TrainingPackLibraryV2.mvpPackId) {
      return 'lesson_push_fold_intro';
    }
    if (widget.template.id == 'push_fold_btn_cash') {
      return 'lesson_push_fold_btn_cash';
    }
    return null;
  }

  Future<void> _checkTheory() async {
    final lessonId = _linkedLessonId();
    if (lessonId == null) return;
    final done =
        await TheoryLessonCompletionLogger.instance.isCompleted(lessonId);
    if (mounted) {
      setState(() => _theoryCompleted = done);
      _maybeShowReward();
    }
  }

  Future<void> _maybeShowReward() async {
    if (!_theoryCompleted || _total == 0 || _completed < _total || _showReward) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('lastRewardedPackId') == widget.template.id) return;
    await prefs.setString('lastRewardedPackId', widget.template.id);
    if (!mounted) return;
    setState(() => _showReward = true);
    _confettiController.play();
    _rewardController.forward(from: 0).whenComplete(() {
      _confettiController.stop();
      if (mounted) setState(() => _showReward = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пак и урок завершены!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (widget.template.id == TrainingPackLibraryV2.mvpPackId) {
          await TrainingProgressLogger.startSession(widget.template.id);
          await const TrainingSessionLauncher().launch(widget.template);
        } else {
          widget.onTap();
        }
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.template.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(widget.template.trainingType.name,
                      style: const TextStyle(color: Colors.white70)),
                ),
                if (widget.template.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(widget.template.tags.join(', '),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                if (_total > 0) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: _completed / _total,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('$_completed / $_total завершено',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          if (_theoryCompleted)
            const Positioned(
              left: 0,
              top: 0,
              child: Tooltip(
                message: 'Теория пройдена',
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(_favorite ? Icons.star : Icons.star_border),
              color: _favorite ? Colors.amber : Colors.white54,
              onPressed: _toggleFavorite,
            ),
          ),
          if (_total > 0 && _completed >= _total)
            const Positioned(
              bottom: 0,
              right: 0,
              child: Tooltip(
                message: 'Пак завершен',
                child: Icon(Icons.emoji_events, color: Colors.amber),
              ),
            ),
          if (_showReward) ...[
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
            ),
            Positioned.fill(
              child: Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(
                      parent: _rewardController, curve: Curves.elasticOut),
                  child:
                      const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
