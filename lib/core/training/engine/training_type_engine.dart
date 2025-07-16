import '../generation/push_fold_pack_generator.dart';
import '../generation/pack_generation_request.dart';
import '../../../models/v2/training_pack_template.dart';
import '../../../models/v2/training_pack_template_v2.dart';

enum TrainingType { pushfold, postflop, exploit, bluffcatch, callrange }

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
    if (request.tags.isNotEmpty) tpl.tags = List<String>.from(request.tags);
    tpl.spotCount = tpl.spots.length;
    return TrainingPackTemplateV2.fromTemplate(
      tpl,
      type: TrainingType.pushfold,
    );
  }
}

class TrainingTypeEngine {
  final Map<TrainingType, TrainingPackBuilder> _builders;
  TrainingTypeEngine({Map<TrainingType, TrainingPackBuilder>? builders})
      : _builders =
            builders ?? const {TrainingType.pushfold: PushFoldPackBuilder()};

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
}
