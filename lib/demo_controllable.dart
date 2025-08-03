import 'models/training_spot.dart';

/// Interface for widgets that can be controlled by the demo playback system.
///
/// Implementers provide mechanisms to load training spots, trigger playback,
/// and handle showdown results so that external controllers can orchestrate
/// demo sequences in a type-safe manner.
mixin DemoControllable {
  /// Loads the given [TrainingSpot] into the analyzer.
  void loadTrainingSpot(TrainingSpot spot);

  /// Plays all actions in the current spot.
  void playAll();

  /// Resolves the hand winner with the provided [winnings] map.
  void resolveWinner(Map<int, int> winnings);
}
