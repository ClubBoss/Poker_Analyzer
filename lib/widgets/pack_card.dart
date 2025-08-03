import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../models/training_type.dart';
import '../services/pack_favorite_service.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/training_session_launcher.dart';
import '../services/theory_lesson_completion_logger.dart';
import '../services/training_progress_tracker_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/training_pack_performance_tracker_service.dart';

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
  bool _locked = false;
  String? _lockMsg;
  double? _accuracy;
  int _handsCompleted = 0;

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
    final stat = await TrainingPackStatsService.getStats(widget.template.id);
    final hands =
        await TrainingPackStatsService.getHandsCompleted(widget.template.id);
    if (mounted) {
      setState(() {
        if (stat != null) _accuracy = stat.accuracy;
        _handsCompleted = hands;
      });
    }
    await _checkPerformance();
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
    if (lessonId == null) {
      if (mounted) {
        setState(() {
          _locked = false;
          _lockMsg = null;
        });
      }
      await _checkPerformance();
      return;
    }
    final done =
        await TheoryLessonCompletionLogger.instance.isCompleted(lessonId);
    if (mounted) {
      setState(() {
        _theoryCompleted = done;
        _locked = widget.template.requiresTheoryCompleted && !done && !kDebugMode;
        _lockMsg = _locked ? 'Сначала пройдите теорию' : null;
      });
      _maybeShowReward();
    }
    await _checkPerformance();
  }

  Future<void> _checkPerformance() async {
    if (widget.template.requiresTheoryCompleted && !_theoryCompleted) return;
    final reqAcc = widget.template.requiredAccuracy;
    final minHands = widget.template.minHands;
    if (reqAcc == null && minHands == null) return;
    final ok = await TrainingPackPerformanceTrackerService.instance
        .meetsRequirements(
      widget.template.id,
      requiredAccuracy: reqAcc,
      minHands: minHands,
    );
    if (!ok && mounted && !kDebugMode) {
      setState(() {
        _locked = true;
        final parts = <String>[];
        if (reqAcc != null) {
          parts.add('точность ≥ ${(reqAcc * 100).toStringAsFixed(0)}%');
        }
        if (minHands != null) {
          parts.add('≥ $minHands рук');
        }
        _lockMsg =
            'Пройдите с ${parts.join(' и ')}, чтобы открыть следующую стадию';
      });
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

  Color _progressColor(double value, double target) {
    if (value >= target) return Colors.green;
    if (value >= target * 0.5) return Colors.yellow;
    return Colors.red;
  }

  Widget _unlockProgress() {
    final reqAcc = widget.template.requiredAccuracy;
    final minHands = widget.template.minHands;
    final widgets = <Widget>[];
    if (reqAcc != null) {
      final accPct = (_accuracy ?? 0) * 100;
      final target = reqAcc * 100;
      final color = _progressColor(accPct, target);
      widgets.add(LinearProgressIndicator(
        value: (_accuracy ?? 0) / reqAcc,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ));
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'Точность: ${accPct.toStringAsFixed(0)}% / ≥${target.toStringAsFixed(0)}%',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ));
    }
    if (minHands != null) {
      final hands = _handsCompleted;
      final color =
          _progressColor(hands.toDouble(), minHands.toDouble());
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: LinearProgressIndicator(
          value: hands / minHands,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ));
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'Руки: $hands / ≥$minHands',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accText = _accuracy != null
        ? ', точность ${(_accuracy! * 100).toStringAsFixed(0)}%'
        : '';
    return GestureDetector(
      onTap: () async {
        if (_locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_lockMsg ?? 'Пак заблокирован')),
          );
          return;
        }
        if (widget.template.id == TrainingPackLibraryV2.mvpPackId) {
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
                if (_locked &&
                    (widget.template.requiredAccuracy != null ||
                        widget.template.minHands != null))
                  _unlockProgress(),
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
                    child: Text(
                      '$_completed / $_total рук$accText',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
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
          if (_locked)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Tooltip(
                    message: _lockMsg ?? 'Пак заблокирован',
                    child: const Icon(Icons.lock, color: Colors.white70, size: 48),
                  ),
                ),
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
