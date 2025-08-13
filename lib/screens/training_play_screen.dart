import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/evaluation_result.dart';
import '../services/training_session_controller.dart';
import '../widgets/training_spot_diagram.dart';
import '../widgets/replay_spot_widget.dart';
import '../widgets/sync_status_widget.dart';
import '../models/training_spot.dart';
import '../models/training_spot_attempt.dart';
import '../models/v2/training_pack_spot.dart';
import '../app_bootstrap.dart';
import '../services/training_session_fingerprint_service.dart';
import '../controllers/pack_run_controller.dart';
import '../models/recall_snippet_result.dart';
import '../models/pack_run_session_state.dart';
import '../widgets/inline_theory_recall_card.dart';
import '../widgets/mistake_inline_theory_prompt.dart';
import '../services/analytics_service.dart';
import '../services/mistake_tag_classifier.dart';
import '../services/user_error_rate_service.dart';
import '../services/spaced_review_service.dart';
import '../services/inline_recall_metrics.dart';
import '../services/recall_cooldown_service.dart';

class TrainingPlayScreen extends StatefulWidget {
  final LessonMatchProvider? lessonMatchProvider;
  final AnalyticsLogger? theoryLogger;
  final PackRunController? packController;

  const TrainingPlayScreen({
    super.key,
    this.lessonMatchProvider,
    this.theoryLogger,
    this.packController,
  });

  @override
  State<TrainingPlayScreen> createState() => _TrainingPlayScreenState();
}

class _TrainingPlayScreenState extends State<TrainingPlayScreen> {
  EvaluationResult? _result;
  PackRunController? _packController;
  RecallSnippetResult? _recall;
  bool _showRetryCTA = false;
  bool _autoRetest = false;
  bool _retesting = false;
  bool _retestSuggested = false;
  String? _retestPackId;
  String? _retestSpotId;
  String? _retestLessonId;
  TrainingSpotAttempt? _lastAttempt;

  @override
  void initState() {
    super.initState();
    _loadAutoRetest();
    if (widget.packController != null) {
      _packController = widget.packController;
    } else {
      final training = context.read<TrainingSessionController>();
      final fpService = AppBootstrap.registry
          .get<TrainingSessionFingerprintService>();
      fpService.startSession().then((sessionId) {
        final packId = training.template?.id ?? training.packId;
        final key = PackRunSessionState.keyFor(
          packId: packId,
          sessionId: sessionId,
        );
        PackRunSessionState.load(key).then((state) {
          if (!mounted) return;
          setState(() {
            _packController = PackRunController(
              packId: packId,
              sessionId: sessionId,
              state: state,
            );
          });
        });
      });
    }
  }

  Future<void> _loadAutoRetest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoRetest = prefs.getBool('auto_retest_after_theory') ?? false;
    });
  }

  Future<void> _setAutoRetest(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_retest_after_theory', v);
    setState(() => _autoRetest = v);
  }

  Future<void> _onTheoryViewed(
    String spotId,
    String packId,
    String? lessonId,
  ) async {
    if (_result?.correct == false && !_retestSuggested) {
      _retestSuggested = true;
      _retestPackId = packId;
      _retestSpotId = spotId;
      _retestLessonId = lessonId;
      await AnalyticsService.instance.logEvent(
        'retest_suggested_after_theory',
        {
          'packId': packId,
          'spotId': spotId,
          if (lessonId != null) 'lessonId': lessonId,
        },
      );
      if (_autoRetest) {
        _startRetry();
      } else {
        setState(() => _showRetryCTA = true);
      }
    }
  }

  void _startRetry() async {
    if (_retestPackId == null || _retestSpotId == null) return;
    await AnalyticsService.instance.logEvent('retest_started_after_theory', {
      'packId': _retestPackId!,
      'spotId': _retestSpotId!,
      if (_retestLessonId != null) 'lessonId': _retestLessonId,
    });
    setState(() {
      _result = null;
      _recall = null;
      _showRetryCTA = false;
      _retesting = true;
    });
  }

  Future<void> _choose(String action) async {
    final controller = context.read<TrainingSessionController>();
    final spot = controller.currentSpot!;
    final prevRecallTag = _recall?.tagId;
    final res = await controller.evaluateSpot(context, spot, action);
    final packSpot = TrainingPackSpot.fromTrainingSpot(spot);
    final attempt = TrainingSpotAttempt(
      spot: packSpot,
      userAction: action.toLowerCase(),
      correctAction: res.expectedAction.toLowerCase(),
      evDiff: res.userEquity - res.expectedEquity,
    );
    final tags = {
      for (final t in spot.tags) t.toLowerCase(),
      ...const MistakeTagClassifier()
          .classifyTheory(attempt)
          .map((e) => e.toLowerCase()),
    };
    await UserErrorRateService.instance.recordAttempt(
      packId: controller.template?.id ?? controller.packId,
      tags: tags,
      isCorrect: res.correct,
      ts: DateTime.now(),
    );
    if (!res.correct) {
      await context.read<SpacedReviewService>().recordMistake(
        spot.id,
        controller.template?.id ?? controller.packId,
      );
    }
    await context.read<SpacedReviewService>().recordReviewOutcome(
      spot.id,
      controller.template?.id ?? controller.packId,
      res.correct,
    );
    await AppBootstrap.registry
        .get<TrainingSessionFingerprintService>()
        .logAttempt(attempt, shownTheoryTags: tags.toList());
    if (prevRecallTag != null) {
      await recordInlineRecallOutcome(
        stage: 'l2',
        tag: prevRecallTag,
        correct: res.correct,
      );
    }
    final snippet = await _packController?.onResult(
      packSpot.id,
      res.correct,
      tags.toList(),
    );
    RecallSnippetResult? gated;
    if (snippet != null) {
      final cooldown = await RecallCooldownService.instance;
      if (cooldown.canShow(snippet.tagId)) {
        await cooldown.markShown(snippet.tagId);
        gated = snippet;
      }
    }
    setState(() {
      _result = res;
      _recall = gated;
      _lastAttempt = attempt;
    });
    if (_retesting) {
      await AnalyticsService.instance.logEvent('retest_outcome_after_theory', {
        'packId':
            _retestPackId ?? (controller.template?.id ?? controller.packId),
        'spotId': _retestSpotId ?? spot.id,
        if (_retestLessonId != null) 'lessonId': _retestLessonId,
        'success': res.correct,
      });
      _retesting = false;
      _retestSuggested = false;
      _retestPackId = _retestSpotId = _retestLessonId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingSessionController>();
    final spot = controller.currentSpot!;
    final correct = _result?.correct ?? false;
    final expected = _result?.expectedAction;
    final actionsEnabled = _packController != null && _result == null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrainingSpotDiagram(
              spot: spot,
              size: MediaQuery.of(context).size.width - 32,
            ),
            const SizedBox(height: 16),
            if (_result == null) ...[
              const Text(
                'Ваше действие?',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: spot.actionType == SpotActionType.callPush
                    ? [
                        ElevatedButton(
                          onPressed: actionsEnabled
                              ? () => _choose('CALL')
                              : null,
                          child: const Text('CALL'),
                        ),
                        ElevatedButton(
                          onPressed: actionsEnabled
                              ? () => _choose('FOLD')
                              : null,
                          child: const Text('FOLD'),
                        ),
                      ]
                    : [
                        ElevatedButton(
                          onPressed: actionsEnabled
                              ? () => _choose('PUSH')
                              : null,
                          child: const Text('PUSH'),
                        ),
                        ElevatedButton(
                          onPressed: actionsEnabled
                              ? () => _choose('FOLD')
                              : null,
                          child: const Text('FOLD'),
                        ),
                      ],
              ),
            ] else ...[
              Text(
                correct ? 'Верно!' : 'Неверно. Надо $expected',
                style: TextStyle(
                  color: correct ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_recall != null) ...[
                InlineTheoryRecallCard(
                  snippet: _recall!.snippet,
                  snippets: _recall!.allSnippets,
                  onDismiss: () => setState(() => _recall = null),
                ),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: () => setState(() {
                  _result = null;
                  _recall = null;
                }),
                child: const Text('Try Again'),
              ),
              if (_showRetryCTA)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('Retry now'),
                        onPressed: _startRetry,
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(value: _autoRetest, onChanged: _setAutoRetest),
                          const Text('Auto-retest after theory'),
                        ],
                      ),
                    ],
                  ),
                )
              else if (!correct && _lastAttempt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: MistakeInlineTheoryPrompt(
                    attempt: _lastAttempt!,
                    packId: controller.template?.id ?? controller.packId,
                    spotId: spot.id,
                    matchProvider: widget.lessonMatchProvider,
                    log: widget.theoryLogger,
                    onTheoryViewed: _onTheoryViewed,
                  ),
                ),
              if (spot.actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.grey[900],
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => ReplaySpotWidget(spot: spot),
                      );
                    },
                    child: const Text('Replay Hand'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
