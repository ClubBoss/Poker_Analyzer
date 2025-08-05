import 'training_pack_template_set.dart';

class TrainingPackTemplateSetGroup {
  final String packId;
  final String title;
  final List<TrainingPackTemplateSet> sets;
  final List<String> tags;

  TrainingPackTemplateSetGroup({
    required this.packId,
    required this.title,
    List<TrainingPackTemplateSet>? sets,
    List<String>? tags,
  }) : sets = sets ?? const [],
       tags = tags ?? const [];
}
