import '../generation/push_fold_pack_generator.dart';
import '../generation/pack_generation_request.dart';
import '../../../models/v2/training_pack_template.dart';
import '../../../models/v2/training_pack_template_v2.dart';

enum TrainingType { pushFold, postflop, icm, bounty, custom, quiz }

abstract class TrainingPackBuilder {
  Future<TrainingPackTemplateV2> build(PackGenerationRequest request);
}

class PushFoldPackBuilder implements TrainingPackBuilder {
  final PushFoldPackGenerator _generator;
  const PushFoldPackBuilder({PushFoldPackGenerator? generator})
      : _generator = generator ?? const PushFoldPackGenerator();

  @override
  Future<TrainingPackTemplateV2> build(PackGenerationRequest request) async {
    final tpl = _generator.generate(
      gameType: request.gameType,
      bb: request.bb,
      bbList: request.bbList,
      positions: request.positions,
      count: request.count,
      rangeGroup: request.rangeGroup,
      multiplePositions: request.multiplePositions,
    );
    if (request.title.isNotEmpty) tpl.name = request.title;
    if (request.description.isNotEmpty) tpl.description = request.description;
    if (request.goal.isNotEmpty) tpl.goal = request.goal;
    if (request.audience.isNotEmpty) tpl.meta['audience'] = request.audience;
    if (request.tags.isNotEmpty) tpl.tags = List<String>.from(request.tags);
    tpl.spotCount = tpl.spots.length;
    final res = TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: TrainingType.pushFold,
    );
    res.audience = tpl.meta['audience'] as String?;
    return res;
  }
}

class TrainingTypeEngine {
  final Map<TrainingType, TrainingPackBuilder> _builders;
  TrainingTypeEngine({Map<TrainingType, TrainingPackBuilder>? builders})
      : _builders =
            builders ?? const {TrainingType.pushFold: PushFoldPackBuilder()};

  Future<TrainingPackTemplateV2> build(
    TrainingType type,
    PackGenerationRequest request,
  ) {
    final builder = _builders[type];
    if (builder == null) {
      throw UnsupportedError('Unsupported training type: $type');
    }
    return builder.build(request);
  }

  TrainingType detectTrainingType(TrainingPackTemplateV2 pack) {
    final tags = {
      ...pack.tags.map((e) => e.toLowerCase()),
      if (pack.meta['tags'] is List)
        ...List.from(pack.meta['tags']).map((e) => e.toString().toLowerCase())
    };
    if (tags.contains('quiz')) return TrainingType.quiz;
    if (tags.contains('bounty')) return TrainingType.bounty;
    if (tags.contains('icm')) return TrainingType.icm;
    final hasPostflop = pack.spots.any((s) {
      if (s.hand.board.isNotEmpty) return true;
      return s.hand.actions.entries.any((e) => e.key > 0 && e.value.isNotEmpty);
    });
    if (hasPostflop) return TrainingType.postflop;
    final allPfNoActions = pack.spots.isNotEmpty &&
        pack.spots.every((s) {
          final noActions =
              s.hand.actions.values.every((l) => l.isEmpty);
          final preflopOnly = s.hand.board.isEmpty &&
              s.hand.actions.keys.every((k) => k == 0);
          return preflopOnly && noActions;
        });
    if (allPfNoActions) return TrainingType.pushFold;
    return TrainingType.custom;
  }
}
