import '../widgets/poker_table_view.dart' show PlayerAction;
import 'v2/training_pack_spot.dart';

class Mistake {
  final TrainingPackSpot spot;
  final PlayerAction action;
  final double handStrength;
  String? category;

  Mistake({
    required this.spot,
    required this.action,
    required this.handStrength,
    this.category,
  });
}
