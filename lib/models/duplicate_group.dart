import 'v2/training_pack_template_v2.dart';

class DuplicateGroup {
  final String type;
  final String key;
  final List<TrainingPackTemplateV2> matches;
  const DuplicateGroup({
    required this.type,
    required this.key,
    required this.matches,
  });
}
