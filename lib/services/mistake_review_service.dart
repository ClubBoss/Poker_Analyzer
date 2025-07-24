import 'package:flutter/foundation.dart';

import '../models/mistake.dart';
import 'mistake_categorization_engine.dart';

class MistakeReviewService extends ChangeNotifier {
  final List<Mistake> _mistakes = [];
  List<Mistake> get mistakes => List.unmodifiable(_mistakes);

  void addMistake(Mistake mistake) {
    const engine = MistakeCategorizationEngine();
    final result = engine.categorize(mistake);
    mistake.category = result.isNotEmpty ? result : 'Unclassified';
    _mistakes.add(mistake);
    notifyListeners();
  }
}
