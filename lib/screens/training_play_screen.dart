import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class TrainingPlayScreen extends StatefulWidget {
  const TrainingPlayScreen({super.key});

  @override
  State<TrainingPlayScreen> createState() => _TrainingPlayScreenState();
}

class _TrainingPlayScreenState extends State<TrainingPlayScreen> {
  EvaluationResult? _result;
  PackRunController? _packController;
  RecallSnippetResult? _recall;

  @override
  void initState() {
    super.initState();
    final training = context.read<TrainingSessionController>();
    final fpService =
        AppBootstrap.registry.get<TrainingSessionFingerprintService>();
    fpService.startSession().then((sessionId) {
      final packId = training.template?.id ?? training.packId;
      final key =
          PackRunSessionState.keyFor(packId: packId, sessionId: sessionId);
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

  Future<void> _choose(String action) async {
    final controller = context.read<TrainingSessionController>();
    final spot = controller.currentSpot!;
    final res = await controller.evaluateSpot(context, spot, action);
    final packSpot = TrainingPackSpot.fromTrainingSpot(spot);
    final attempt = TrainingSpotAttempt(
      spot: packSpot,
      userAction: action.toLowerCase(),
      correctAction: res.expectedAction.toLowerCase(),
      evDiff: res.userEquity - res.expectedEquity,
    );
    final tags = spot.tags;
    await AppBootstrap.registry
        .get<TrainingSessionFingerprintService>()
        .logAttempt(attempt, shownTheoryTags: tags);
    final snippet =
        await _packController?.onResult(packSpot.id, res.correct, tags);
    setState(() {
      _result = res;
      _recall = snippet;
    });
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
              const Text('Ваше действие?',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: spot.actionType == SpotActionType.callPush
                    ? [
                        ElevatedButton(
                          onPressed:
                              actionsEnabled ? () => _choose('CALL') : null,
                          child: const Text('CALL'),
                        ),
                        ElevatedButton(
                          onPressed:
                              actionsEnabled ? () => _choose('FOLD') : null,
                          child: const Text('FOLD'),
                        ),
                      ]
                    : [
                        ElevatedButton(
                          onPressed:
                              actionsEnabled ? () => _choose('PUSH') : null,
                          child: const Text('PUSH'),
                        ),
                        ElevatedButton(
                          onPressed:
                              actionsEnabled ? () => _choose('FOLD') : null,
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
              if (!correct)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: MistakeInlineTheoryPrompt(
                    tags: spot.tags,
                    packId: controller.template?.id ?? controller.packId,
                    spotId: spot.id,
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
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
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
