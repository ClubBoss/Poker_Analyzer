import 'saved_hand.dart'

class TrainingPack {
  final String name;
  final String description;
  final List<SavedHand> hands;

  TrainingPack({
    required this.name,
    required this.description,
    required this.hands,
  });
}
