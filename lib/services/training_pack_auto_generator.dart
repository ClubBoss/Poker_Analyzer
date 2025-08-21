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
import 'board_texture_classifier.dart';
import 'autogen_stats_dashboard_service.dart';
import '../models/texture_filter_config.dart';
import '../core/autogen/texture_filter_engine.dart';

/// Wrapper around [TrainingPackGeneratorEngineV2] that skips duplicate spots.
class TrainingPackAutoGenerator {
  final TrainingPackGeneratorEngineV2 _engine;
  final AutoDeduplicationEngine _dedup;
  final AutogenPackErrorClassifierService _errorClassifier;
  final AutogenErrorStatsLogger? _errorStats;
  final TrainingPackTemplateRegistryService _registry;
  final BoardTextureClassifier _boardClassifier;
  TextureFilterConfig? textureFilters;
  final TextureFilterEngine _textureEngine;
  int spotsPerPack;
  int streets;
  double theoryRatio;
  bool _shouldAbort = false;

  TrainingPackAutoGenerator({
    TrainingPackGeneratorEngineV2? engine,
    AutoDeduplicationEngine? dedup,
    AutogenPackErrorClassifierService? errorClassifier,
    AutogenErrorStatsLogger? errorStats,
    TrainingPackTemplateRegistryService? registry,
    BoardTextureClassifier? boardClassifier,
    TextureFilterConfig? textureFilters,
    TextureFilterEngine? textureEngine,
    this.spotsPerPack = 12,
    this.streets = 1,
    this.theoryRatio = 0.5,
  })  : _engine = engine ?? TrainingPackGeneratorEngineV2(),
        _dedup = dedup ?? AutoDeduplicationEngine(),
        _errorClassifier =
            errorClassifier ?? const AutogenPackErrorClassifierService(),
        _errorStats = errorStats ?? AutogenErrorStatsLogger(),
        _registry = registry ?? TrainingPackTemplateRegistryService(),
        _boardClassifier = boardClassifier ?? const BoardTextureClassifier(),
        textureFilters = textureFilters,
        _textureEngine = textureEngine ?? TextureFilterEngine();

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
    if (set.outputVariants.isNotEmpty) {
      final all = await generateAll(
        set,
        theoryIndex: theoryIndex,
        existingSpots: existingSpots,
        deduplicate: deduplicate,
      );
      return all.isNotEmpty ? all.first.spots : [];
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
      final spots = _engine.generate(
        set,
        theoryIndex: theoryIndex,
        seed: set.seed,
      );
      final filtered = _applyTextureFilters(spots);
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
        return filtered;
      }

      final deduped = _dedup.deduplicateSpots(
        filtered,
        source: set.baseSpot.id,
      );
      if (filtered.isNotEmpty && deduped.isEmpty) {
        final pack = _buildPack(set, spots);
        final type = _errorClassifier.classify(
          pack,
          Exception('duplicate spots'),
        );
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
      return deduped;
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

  /// Generates spot lists for each output variant in [set].
  Future<List<TrainingPackTemplateV2>> generateAll(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    Iterable<TrainingPackSpot> existingSpots = const [],
    bool deduplicate = true,
  }) async {
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
      final results = <TrainingPackTemplateV2>[];
      final variants = set.outputVariants.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      if (variants.isEmpty) {
        var spots = _engine.generate(
          set,
          theoryIndex: theoryIndex,
          seed: set.seed,
        );
        spots = _applyTextureFilters(spots);
        if (deduplicate) {
          spots = _dedup.deduplicateSpots(spots, source: set.baseSpot.id);
        }
        results.add(_buildPack(set, spots));
      } else {
        for (final entry in variants) {
          final variant = entry.value;
          final merged = TrainingPackTemplateSet(
            baseSpot: set.baseSpot,
            variations: [
              for (final v in set.variations)
                _mergeConstraints(v, variant.constraints),
            ],
            playerTypeVariations: set.playerTypeVariations,
            suitAlternation: set.suitAlternation,
            stackDepthMods: set.stackDepthMods,
            linePatterns: set.linePatterns,
            postflopLines: set.postflopLines,
            boardTexturePreset: set.boardTexturePreset,
            excludeBoardTexturePresets: set.excludeBoardTexturePresets,
            requiredBoardClusters: set.requiredBoardClusters,
            excludedBoardClusters: set.excludedBoardClusters,
            expandAllLines: set.expandAllLines,
            postflopLineSeed: set.postflopLineSeed,
            seed: variant.seed ?? set.seed,
          );
          var spots = _engine.generate(
            merged,
            theoryIndex: theoryIndex,
            seed: merged.seed,
          );
          spots = _applyTextureFilters(spots);
          if (deduplicate) {
            spots = _dedup.deduplicateSpots(spots, source: set.baseSpot.id);
          }
          final tag = 'VARIANT:${entry.key.toUpperCase()}';
          for (final s in spots) {
            s.tags = {...s.tags, tag}.toList()..sort();
          }
          final pack = _buildPack(set, spots, variantKey: entry.key);
          results.add(pack);
        }
      }
      status.update(
        'TrainingPackAutoGenerator',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
      return results;
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

  TrainingPackTemplateV2 _buildPack(
    TrainingPackTemplateSet set,
    List<TrainingPackSpot> spots, {
    String? variantKey,
  }) {
    final base = set.baseSpot;
    final baseId = base.id;
    final id = variantKey == null ? baseId : '${baseId}__$variantKey';
    final nameBase = base.title.isNotEmpty ? base.title : base.id;
    final name = variantKey == null ? nameBase : '$nameBase - $variantKey';
    final tagSet = {...base.tags};
    if (variantKey != null) {
      tagSet.add('VARIANT:${variantKey.toUpperCase()}');
    }
    return TrainingPackTemplateV2(
      id: id,
      name: name,
      trainingType: TrainingType.custom,
      spots: spots,
      spotCount: spots.length,
      tags: tagSet.toList()..sort(),
      gameType: GameType.cash,
      bb: base.hand.stacks['0']?.toInt() ?? 0,
      positions: [base.hand.position.name],
      meta: Map<String, dynamic>.from(base.meta),
    );
  }

  ConstraintSet _mergeConstraints(ConstraintSet base, ConstraintSet variant) {
    return ConstraintSet(
      boardTags: base.boardTags,
      positions: base.positions,
      handGroup: base.handGroup,
      villainActions: base.villainActions,
      targetStreet: variant.targetStreet ?? base.targetStreet,
      requiredTags: {...base.requiredTags, ...variant.requiredTags}.toList(),
      excludedTags: {...base.excludedTags, ...variant.excludedTags}.toList(),
      position: base.position,
      opponentPosition: base.opponentPosition,
      boardTexture: base.boardTexture,
      minStack: base.minStack,
      maxStack: base.maxStack,
      boardConstraints: [...base.boardConstraints, ...variant.boardConstraints],
      linePattern: base.linePattern,
      overrides: base.overrides,
      tags: base.tags,
      tagMergeMode: base.tagMergeMode,
      metadata: base.metadata,
      metaMergeMode: base.metaMergeMode,
      theoryLink: base.theoryLink,
    );
  }

  List<TrainingPackSpot> _applyTextureFilters(List<TrainingPackSpot> spots) {
    final config = textureFilters;
    if (config == null) return spots;
    final dashboard = AutogenStatsDashboardService.instance;
    return _textureEngine.filter<TrainingPackSpot>(
      spots,
      (s) => s.hand.board.take(3).join(),
      config.include,
      config.exclude,
      config.targetMix,
      spotsPerPack: spotsPerPack,
      classifier: _boardClassifier,
      onAccept: dashboard.recordTexture,
      onReject: dashboard.recordRejectedTexture,
    );
  }

  /// Requests the generator to stop processing.
  void abort() {
    _shouldAbort = true;
  }

  /// Whether an abort has been requested.
  bool get shouldAbort => _shouldAbort;
}
