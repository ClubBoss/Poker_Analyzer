import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_spot_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'training_session_launcher.dart';
import 'booster_queue_service.dart';
import 'user_action_logger.dart';

/// Launches queued decay booster spots as a training session.
class DecayBoosterTrainingLauncher {
  final BoosterQueueService queue;
  final TrainingSessionLauncher launcher;

  const DecayBoosterTrainingLauncher({
    this.queue = BoosterQueueService.instance,
    this.launcher = const TrainingSessionLauncher(),
  });

  /// Builds a temporary pack from queued spots and launches it.
  Future<void> launch() async {
    final spots = queue.getQueue();
    if (spots.isEmpty) return;

    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Decay Booster',
      tags: const ['decayBooster'],
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );

    await launcher.launch(tpl);
    queue.clear();
    await queue.markUsed();
    await UserActionLogger.instance
        .logEvent({'event': 'decay_booster_completed'});
  }
}
