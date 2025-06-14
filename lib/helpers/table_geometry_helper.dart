import 'dart:math';

class TableGeometryHelper {
  static double tableScale(int numberOfPlayers) {
    final extraPlayers = max(0, numberOfPlayers - 6);
    return (1.0 - extraPlayers * 0.05).clamp(0.75, 1.0);
  }

  static double centerYOffset(int numberOfPlayers, double scale) {
    double base;
    if (numberOfPlayers > 6) {
      base = 200.0 + (numberOfPlayers - 6) * 10.0;
    } else {
      base = 140.0 - (6 - numberOfPlayers) * 10.0;
    }
    return base * scale;
  }

  static double radiusModifier(int numberOfPlayers) {
    return (1 + (6 - numberOfPlayers) * 0.05).clamp(0.8, 1.2);
  }

  static double verticalBiasFromAngle(double angle) {
    return 90 + 20 * sin(angle);
  }
}
