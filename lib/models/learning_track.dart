import 'v2/training_pack_template_v2.dart';

class LearningTrack {
  final List<TrainingPackTemplateV2> unlockedPacks;
  final TrainingPackTemplateV2? nextUpPack;

  const LearningTrack({required this.unlockedPacks, this.nextUpPack});
}
