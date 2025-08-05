import '../models/training_pack_model.dart';
import '../models/training_pack_template_set.dart';
import 'training_pack_template_set_expander_service.dart';

/// Expands a [TrainingPackTemplateSet] into standalone [TrainingPackModel]s.
///
/// Each generated pack contains a single spot produced by
/// [TrainingPackTemplateSetExpanderService]. Shared metadata and tags are
/// merged with per-spot data, and unique ids/titles are assigned based on the
/// provided prefixes.
class TrainingPackTemplateInstanceExpanderService {
  final TrainingPackTemplateSetExpanderService _expander;

  TrainingPackTemplateInstanceExpanderService({
    TrainingPackTemplateSetExpanderService? expander,
  }) : _expander = expander ?? TrainingPackTemplateSetExpanderService();

  /// Generates packs from [set].
  ///
  /// [packIdPrefix] and [title] provide base values for the resulting packs.
  /// Tags and metadata are merged with each spot's own fields.
  List<TrainingPackModel> expand(
    TrainingPackTemplateSet set, {
    String? packIdPrefix,
    String? title,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final spots = _expander.expand(set);
    final baseTitle = title ?? set.baseSpot.title;
    final idPrefix = packIdPrefix ?? set.baseSpot.id;
    final packs = <TrainingPackModel>[];
    for (var i = 0; i < spots.length; i++) {
      final spot = spots[i];
      final id = '${idPrefix}_${i + 1}';
      final boardSuffix =
          spot.board.isNotEmpty ? ' - ${spot.board.join(' ')}' : '';
      final packTitle = '$baseTitle$boardSuffix';
      final mergedTags = {...tags, ...spot.tags}.toList()..sort();
      final mergedMeta = {...metadata, ...spot.meta};
      packs.add(
        TrainingPackModel(
          id: id,
          title: packTitle,
          spots: [spot],
          tags: mergedTags,
          metadata: mergedMeta,
        ),
      );
    }
    return packs;
  }
}

