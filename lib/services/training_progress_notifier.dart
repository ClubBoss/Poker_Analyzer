import 'package:flutter/foundation.dart';

/// Dispatches updates when training progress changes.
class TrainingProgressNotifier extends ChangeNotifier {
  void notifyProgressChanged() => notifyListeners();
}
