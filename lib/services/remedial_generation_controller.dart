import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/remedial_spec.dart';
import '../models/stage_remedial_meta.dart';
import 'autogen_pipeline_executor.dart';
import 'pack_registry_service.dart';
import 'learning_path_telemetry.dart';

class RemedialGenerationController {
  final PackRegistryService _registry;
  final Future<double> Function(String stageId) _accuracyFetcher;
  final Future<String> Function({
    required String presetId,
    Map<String, dynamic>? extras,
    int? spotsPerPack,
  }) _autogenRunner;

  RemedialGenerationController({
    PackRegistryService? registry,
    Future<double> Function(String stageId)? accuracyFetcher,
    Future<String> Function({
      required String presetId,
      Map<String, dynamic>? extras,
      int? spotsPerPack,
    })?
        autogenRunner,
  })  : _registry = registry ?? PackRegistryService.instance,
        _accuracyFetcher = accuracyFetcher ?? ((_) async => 0.0),
        _autogenRunner = autogenRunner ?? ({
          required String presetId,
          Map<String, dynamic>? extras,
          int? spotsPerPack,
        }) async {
          final exec = AutogenPipelineExecutor();
          final dyn = exec as dynamic;
          return await dyn.run(
            presetId: presetId,
            extras: extras,
            spotsPerPack: spotsPerPack,
          ) as String;
        };

  Future<Uri> createRemedialPack({
    required String pathId,
    required String stageId,
    RemedialSpec? specOverride,
    int? spotsPerPack,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'learning.remedial.$pathId.$stageId';
    StageRemedialMeta? meta;
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        meta = StageRemedialMeta.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    final currentAccuracy = await _accuracyFetcher(stageId);
    if (meta != null) {
      final age = DateTime.now().difference(meta.createdAt);
      final improved = currentAccuracy - meta.accuracyAfter >= 0.08;
      if (age < const Duration(days: 7) && !improved) {
        return Uri(
          path: '/pathPlayer',
          queryParameters: {
            'pathId': pathId,
            'stageId': stageId,
            'sideQuestId': meta.remedialPackId,
          },
        );
      }
    }

    final spec = specOverride ?? const RemedialSpec();
    final extras = <String, dynamic>{
      'pathId': pathId,
      'stageId': stageId,
      if (spec.topTags.isNotEmpty) 'boostTags': spec.topTags,
    };
    final packId = await _autogenRunner(
      presetId: 'remedial_v1',
      extras: extras,
      spotsPerPack: (spotsPerPack ?? 6).clamp(6, 12),
    );

    _registry.registerGenerated(
      packId,
      source: 'remedial',
      meta: {'pathId': pathId, 'stageId': stageId},
    );

    final metaToSave = StageRemedialMeta(
      remedialPackId: packId,
      sourceAttempts: 0,
      missTags: {
        for (final t in spec.topTags) t: 1,
      },
      missTextures: spec.textureCounts,
      accuracyAfter: currentAccuracy,
    );
    await prefs.setString(key, jsonEncode(metaToSave.toJson()));

    LearningPathTelemetry.instance.log('remedial_created', {
      'pathId': pathId,
      'stageId': stageId,
      'remedialPackId': packId,
      if (spec.topTags.isNotEmpty) 'missTags': spec.topTags,
      if (spec.textureCounts.isNotEmpty) 'missTextures': spec.textureCounts,
    });

    return Uri(
      path: '/pathPlayer',
      queryParameters: {
        'pathId': pathId,
        'stageId': stageId,
        'sideQuestId': packId,
      },
    );
  }
}
