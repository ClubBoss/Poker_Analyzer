import '../models/v2/training_pack_template_v2.dart';

const kTplPriority = ['Push/Fold', 'ICM', 'Postflop', '3-бет'];

extension SortedByPriority on Iterable<TrainingPackTemplateV2> {
  List<TrainingPackTemplateV2> sortedByPriority() {
    final map = {
      for (var i = 0; i < kTplPriority.length; i++) kTplPriority[i]: i,
    };
    return toList()
      ..sort((a, b) {
        final pa = map[a.category] ?? 999;
        final pb = map[b.category] ?? 999;
        return pa != pb ? pa - pb : a.name.compareTo(b.name);
      });
  }
}
