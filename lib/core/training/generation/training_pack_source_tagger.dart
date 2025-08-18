import '../../../models/v2/training_pack_template_v2.dart';

enum PackSource { yaml, auto, gpt, manual }

class TrainingPackSourceTagger {
  const TrainingPackSourceTagger();

  void tag(TrainingPackTemplateV2 template, {required String source}) {
    final current = template.meta['source'];
    if (current == null || current.toString().isEmpty) {
      template.meta['source'] = source;
    }
  }
}
