import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_filter_engine.dart';

class SmartPackRecommendationEngine {
  const SmartPackRecommendationEngine();

  Future<List<TrainingPackTemplateV2>> recommend({
    required String audience,
    required List<String> interests,
  }) async {
    final list = await const TrainingPackFilterEngine().filter(
      minRating: 70,
      tags: interests,
      audience: audience,
    );
    return list.take(5).toList();
  }
}
