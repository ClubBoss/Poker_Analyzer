import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../models/training_type.dart';
import '../services/analytics_service.dart';
import '../services/pack_favorite_service.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/training_session_launcher.dart';
import '../services/theory_lesson_completion_logger.dart';
import '../services/training_progress_tracker_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/training_pack_performance_tracker_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../screens/mini_lesson_screen.dart';
import 'pack_progress_summary_widget.dart';

class PackCard extends StatefulWidget {
  final TrainingPackTemplateV2 template;
  final VoidCallback onTap;
  const PackCard({super.key, required this.template, required this.onTap});

  @override
  State<PackCard> createState() => _PackCardState();
}

class _PackCardState extends State<PackCard>
    with SingleTickerProviderStateMixin {
  late bool _favorite;
  bool _theoryCompleted = false;
  int _completed = 0;
  late int _total;
  bool _locked = false;
  String? _lockMsg;
  double? _accuracy;
  int _handsCompleted = 0;
  bool _almostUnlocked = false;

  bool _showReward = false;
  late final AnimationController _rewardController;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _favorite = PackFavoriteService.instance.isFavorite(widget.template.id);
    _total = widget.template.spots.isNotEmpty
        ? widget.template.spots.length
        : widget.template.spotCount;
    _rewardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
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
    final hands = await TrainingPackStatsService.getHandsCompleted(
      widget.template.id,
    );
    if (mounted) {
      setState(() {
        if (stat != null) _accuracy = stat.accuracy;
        _handsCompleted = hands;
        final reqAcc = widget.template.requiredAccuracy;
        final minHands = widget.template.minHands;
        double accRatio = 0;
        double handsRatio = 0;
        if (stat != null && reqAcc != null && reqAcc > 0) {
          accRatio = (stat.accuracy * 100) / reqAcc;
        }
        if (minHands != null && minHands > 0) {
          handsRatio = hands / minHands;
        }
        _almostUnlocked =
            (accRatio >= 0.5 && accRatio < 1) ||
            (handsRatio >= 0.5 && handsRatio < 1);
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
    final done = await TheoryLessonCompletionLogger.instance.isCompleted(
      lessonId,
    );
    if (mounted) {
      setState(() {
        _theoryCompleted = done;
        _locked =
            widget.template.requiresTheoryCompleted && !done && !kDebugMode;
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
          requiredAccuracy: reqAcc != null ? reqAcc / 100 : null,
          minHands: minHands,
        );
    if (!ok && mounted && !kDebugMode) {
      setState(() {
        _locked = true;
        if (reqAcc != null && minHands != null) {
          _lockMsg =
              'Достигните точности ${reqAcc.toStringAsFixed(0)}% и сыграйте $minHands рук, чтобы открыть';
        } else if (reqAcc != null) {
          _lockMsg =
              'Достигните точности ${reqAcc.toStringAsFixed(0)}%, чтобы открыть';
        } else if (minHands != null) {
          _lockMsg = 'Сыграйте $minHands рук, чтобы открыть';
        }
      });
    }
  }

  Future<void> _maybeShowReward() async {
    if (!_theoryCompleted ||
        _total == 0 ||
        _completed < _total ||
        _showReward) {
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Пак и урок завершены!')));
  }

  Future<void> _showLockDetails() async {
    final reqAcc = widget.template.requiredAccuracy;
    final minHands = widget.template.minHands;
    final needsTheory = widget.template.requiresTheoryCompleted;
    final needsTheoryAction = needsTheory && !_theoryCompleted;
    final lessonId = needsTheoryAction ? _linkedLessonId() : null;
    final rootCtx = context;

    await showDialog(
      context: rootCtx,
      builder: (context) {
        return AlertDialog(
          title: const Text('Условия разблокировки'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (needsTheory)
                Text(
                  'Теория: ' + (_theoryCompleted ? 'пройдена' : 'не пройдена'),
                ),
              if (reqAcc != null)
                Text(
                  'Точность: ${((_accuracy ?? 0) * 100).toStringAsFixed(0)} / ${reqAcc.toStringAsFixed(0)}%',
                ),
              if (minHands != null) Text('Руки: $_handsCompleted / $minHands'),
            ],
          ),
          actions: [
            if (needsTheoryAction && lessonId != null)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await MiniLessonLibraryService.instance.loadAll();
                  final lesson =
                      MiniLessonLibraryService.instance.getById(lessonId);
                  if (lesson != null) {
                    await Navigator.of(rootCtx).push(
                      MaterialPageRoute(
                        builder: (_) => MiniLessonScreen(lesson: lesson),
                      ),
                    );
                    if (!mounted) return;
                    await _checkTheory();
                  }
                },
                child: const Text('Пройти теорию'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String? get _ctaText {
    final reqAcc = widget.template.requiredAccuracy;
    final minHands = widget.template.minHands;
    final accShort =
        reqAcc != null && (_accuracy ?? 0) * 100 < reqAcc;
    if (accShort) return 'Улучшить точность';
    final handsShort =
        minHands != null && _handsCompleted < minHands;
    if (handsShort) return 'Сыграть руки';
    return null;
  }

  Future<void> _handleCta(BuildContext context) async {
    if (_ctaText != null) {
      unawaited(
        AnalyticsService.instance.logEvent('locked_pack_cta_tap', {
          'pack_id': widget.template.id,
          'cta_type': _ctaText,
          'accuracy': _accuracy,
          'hands_completed': _handsCompleted,
          'required_accuracy': widget.template.requiredAccuracy,
          'min_hands': widget.template.minHands,
        }),
      );
    }
    await Navigator.of(context, rootNavigator: true).maybePop();
    await const TrainingSessionLauncher().launch(widget.template);
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
      onLongPress: _locked ? _showLockDetails : null,
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
                Text(
                  widget.template.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.template.trainingType.name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                if (!_locked &&
                    ((widget.template.requiredAccuracy ?? 0) > 0 ||
                        (widget.template.minHands ?? 0) > 0))
                  PackProgressSummaryWidget(
                    accuracy: _accuracy,
                    handsCompleted: _handsCompleted,
                    requiredAccuracy: widget.template.requiredAccuracy,
                    minHands: widget.template.minHands,
                  ),
                if (widget.template.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.template.tags.join(', '),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_total > 0) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      value: _completed / _total,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$_completed / $_total рук$accText',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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
          if (_locked && _almostUnlocked)
            Positioned(
              top: 0,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Почти разблокировано',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Tooltip(
                          message: _lockMsg ?? 'Пак заблокирован',
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white70,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if ((widget.template.requiredAccuracy ?? 0) > 0 ||
                      (widget.template.minHands ?? 0) > 0)
                    Container(
                      width: double.infinity,
                      color: Colors.black87,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PackProgressSummaryWidget(
                            accuracy: _accuracy,
                            handsCompleted: _handsCompleted,
                            requiredAccuracy: widget.template.requiredAccuracy,
                            minHands: widget.template.minHands,
                          ),
                          const SizedBox(height: 8),
                          if (_ctaText != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _handleCta(context),
                                child: Text(_ctaText!),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
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
                    parent: _rewardController,
                    curve: Curves.elasticOut,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
