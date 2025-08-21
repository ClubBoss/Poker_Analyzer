import '../models/v2/training_pack_template_v2.dart';

/// Extracts theory spots from a training pack template.
class TheoryPackSampler {
  const TheoryPackSampler();

  /// Returns a new [TrainingPackTemplateV2] containing only spots
  /// with `type == "theory"`. Returns `null` if no such spots exist.
  TrainingPackTemplateV2? sample(TrainingPackTemplateV2 fullPack) {
    final theorySpots =
        fullPack.spots.where((s) => s.type == 'theory').toList();
    if (theorySpots.isEmpty) return null;

    final map = fullPack.toJson();
    map['id'] = '${fullPack.id}-theory';
    map['name'] = '📘 Теория: ${fullPack.name}';
    map['spots'] = [for (final s in theorySpots) s.toJson()];
    map['spotCount'] = theorySpots.length;
    final result = TrainingPackTemplateV2.fromJson(
      Map<String, dynamic>.from(map),
    );
    result.isSampledPack = true;
    return result;
  }
}
