import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';

class ICMLibrary {
  static final Map<String, List<TrainingPackSpot>> spotsByType = {
    'finalTable': [
      TrainingPackSpot(
        id: 'icm_ft_1',
        title: 'Final table shove spot',
        hand: HandData.fromSimpleInput('Ah Qh', HeroPosition.btn, 10),
      ),
    ],
    'bubble': [
      TrainingPackSpot(
        id: 'icm_bubble_1',
        title: 'Bubble shove spot',
        hand: HandData.fromSimpleInput('7s 7c', HeroPosition.sb, 12),
      ),
    ],
    'late': [
      TrainingPackSpot(
        id: 'icm_late_1',
        title: 'Late stage call spot',
        hand: HandData.fromSimpleInput('Kc Qc', HeroPosition.co, 15),
      ),
    ],
  };
}
