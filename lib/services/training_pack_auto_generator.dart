import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/autogen_status.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import 'training_pack_generator_engine_v2.dart';
import 'auto_deduplication_engine.dart';
import 'autogen_status_dashboard_service.dart';
import 'autogen_pack_error_classifier_service.dart';
import 'autogen_error_stats_logger.dart';
import 'training_pack_template_registry_service.dart';

/// Wrapper around [TrainingPackGeneratorEngineV2] that skips duplicate spots.
class TrainingPackAutoGenerator {
  final TrainingPackGeneratorEngineV2 _engine;
  final AutoDeduplicationEngine _dedup;
  final AutogenPackErrorClassifierService _errorClassifier;
  final AutogenErrorStatsLogger? _errorStats;
  final TrainingPackTemplateRegistryService _registry;
  bool _shouldAbort = false;

  TrainingPackAutoGenerator({
    TrainingPackGeneratorEngineV2? engine,
    AutoDeduplicationEngine? dedup,
    AutogenPackErrorClassifierService? errorClassifier,
    AutogenErrorStatsLogger? errorStats,
    TrainingPackTemplateRegistryService? registry,
  })  : _engine = engine ?? TrainingPackGeneratorEngineV2(),
        _dedup = dedup ?? AutoDeduplicationEngine(),
        _errorClassifier =
            errorClassifier ?? const AutogenPackErrorClassifierService(),
        _errorStats = errorStats ?? AutogenErrorStatsLogger(),
        _registry = registry ?? TrainingPackTemplateRegistryService();

  /// Generates spots from [template] and optionally deduplicates them based on
  /// fingerprints.
  ///
  /// When [template] is a [TrainingPackTemplateSet] it is processed normally.
  /// Passing any other type will result in an [ArgumentError]. This allows
  /// callers to eventually support invoking the generator by template id.
  Future<List<TrainingPackSpot>> generate(
    dynamic template, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    Iterable<TrainingPackSpot> existingSpots = const [],
    bool deduplicate = true,
  }) async {
    TrainingPackTemplateSet set;
    if (template is TrainingPackTemplateSet) {
      set = template;
    } else if (template is String) {
      set = await _registry.loadTemplateById(template);
    } else {
      throw ArgumentError('Expected TrainingPackTemplateSet or templateId');
    }
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
      if (spots.isEmpty) {
        final pack = _buildPack(set, spots);
        final type = _errorClassifier.classify(pack, null);
        _errorStats?.log(type);
      }
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
      if (spots.isNotEmpty && filtered.isEmpty) {
        final pack = _buildPack(set, spots);
        final type =
            _errorClassifier.classify(pack, Exception('duplicate spots'));
        _errorStats?.log(type);
      }
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
      final pack = _buildPack(set, const []);
      final type = _errorClassifier.classify(
        pack,
        e is Exception ? e : Exception(e.toString()),
      );
      _errorStats?.log(type);
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

  TrainingPackTemplateV2 _buildPack(
    TrainingPackTemplateSet set,
    List<TrainingPackSpot> spots,
  ) {
    final base = set.baseSpot;
    return TrainingPackTemplateV2(
      id: base.id,
      name: base.title.isNotEmpty ? base.title : base.id,
      trainingType: TrainingType.custom,
      spots: spots,
      spotCount: spots.length,
      tags: List<String>.from(base.tags),
      gameType: GameType.cash,
      bb: base.hand.stacks['0']?.toInt() ?? 0,
      positions: [base.hand.position.name],
      meta: Map<String, dynamic>.from(base.meta),
    );
  }

  /// Requests the generator to stop processing.
  void abort() {
    _shouldAbort = true;
  }

  /// Whether an abort has been requested.
  bool get shouldAbort => _shouldAbort;
}
