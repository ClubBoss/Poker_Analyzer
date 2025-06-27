import '../models/training_pack_template_model.dart';

class TrainingPackTemplateRepository {
  static Future<List<TrainingPackTemplateModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const TrainingPackTemplateModel(
        id: '1',
        name: 'Default Pack',
        description: 'Starter set',
        category: 'Basic',
        difficulty: 1,
      ),
      const TrainingPackTemplateModel(
        id: '2',
        name: 'Advanced Pack',
        description: 'For pros',
        category: 'Pro',
        difficulty: 3,
      ),
    ];
  }
}
