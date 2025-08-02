import 'theory_block_model.dart';

/// Represents a linear collection of [TheoryBlockModel]s.
class TheoryTrackModel {
  final String id;
  final String title;
  final List<TheoryBlockModel> blocks;

  const TheoryTrackModel({
    required this.id,
    required this.title,
    required this.blocks,
  });

  factory TheoryTrackModel.fromYaml(Map yaml) {
    final list = yaml['blocks'];
    final blocks = <TheoryBlockModel>[];
    if (list is List) {
      for (final v in list) {
        if (v is Map) {
          blocks.add(TheoryBlockModel.fromYaml(Map<String, dynamic>.from(v)));
        }
      }
    }
    return TheoryTrackModel(
      id: yaml['id']?.toString() ?? '',
      title: yaml['title']?.toString() ?? '',
      blocks: blocks,
    );
  }
}
