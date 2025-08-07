import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/autogen_status.dart';
import 'training_pack_generator_engine_v2.dart';
import 'auto_deduplication_engine.dart';
import 'autogen_status_dashboard_service.dart';

/// Wrapper around [TrainingPackGeneratorEngineV2] that skips duplicate spots.
class TrainingPackAutoGenerator {
  final TrainingPackGeneratorEngineV2 _engine;
  final AutoDeduplicationEngine _dedup;
  bool _shouldAbort = false;

  TrainingPackAutoGenerator({
    TrainingPackGeneratorEngineV2? engine,
    AutoDeduplicationEngine? dedup,
  })  : _engine = engine ?? TrainingPackGeneratorEngineV2(),
        _dedup = dedup ?? AutoDeduplicationEngine();

  /// Generates spots from [set] and optionally deduplicates them based on
  /// fingerprints.
  List<TrainingPackSpot> generate(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    Iterable<TrainingPackSpot> existingSpots = const [],
    bool deduplicate = true,
  }) {
    final status = AutogenStatusDashboardService.instance;
    if (_shouldAbort) {
      status.update(
        'TrainingPackAutoGenerator',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'aborted',
          progress: 0,
        ),
      );
      return [];
    }
    status.update(
      'TrainingPackAutoGenerator',
      const AutogenStatus(
        isRunning: true,
        currentStage: 'generating',
        progress: 0,
      ),
    );
    try {
      if (deduplicate) {
        _dedup.addExisting(existingSpots);
      }
      final spots = _engine.generate(set, theoryIndex: theoryIndex);
      if (_shouldAbort || !deduplicate) {
        status.update(
          'TrainingPackAutoGenerator',
          const AutogenStatus(
            isRunning: false,
            currentStage: 'complete',
            progress: 1,
          ),
        );
        return spots;
      }

      final filtered = _dedup.deduplicate(spots, source: set.baseSpot.id);
      status.update(
        'TrainingPackAutoGenerator',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
      return filtered;
    } catch (e) {
      status.update(
        'TrainingPackAutoGenerator',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Requests the generator to stop processing.
  void abort() {
    _shouldAbort = true;
  }

  /// Whether an abort has been requested.
  bool get shouldAbort => _shouldAbort;
}
