import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../models/training_pack.dart';

import 'training_pack_core.dart';

class TrainingPackScreen extends TrainingPackCore {
  const TrainingPackScreen({
    super.key,
    required TrainingPack pack,
    List<SavedHand>? hands,
    bool mistakeReviewMode = false,
    ValueChanged<bool>? onComplete,
    bool persistResults = true,
    int? initialPosition,
  }) : super(
         pack: pack,
         hands: hands,
         mistakeReviewMode: mistakeReviewMode,
         onComplete: onComplete,
         persistResults: persistResults,
         initialPosition: initialPosition,
       );
}
