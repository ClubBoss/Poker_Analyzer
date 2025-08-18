import 'dart:math';
import 'dart:ui';

class TableGeometryHelper {
  static double tableScale(int numberOfPlayers) {
    final int extraPlayers = max(0, numberOfPlayers - 6);
    return (1.0 - extraPlayers * 0.05).clamp(0.75, 1.0);
  }

  /// Calculates the center offset for the table. The new painted table is
  /// perfectly centered so no additional offset is required.
  static double centerYOffset(int numberOfPlayers, double scale) {
    return 0;
  }

  /// Modifier for the distance of players from the center. With the new table
  /// rendering we keep players on the ellipse edge so the modifier is 1.
  static double radiusModifier(int numberOfPlayers) {
    return 1.0;
  }

  /// Additional vertical bias for each player position. The old PNG based table
  /// required a bias to visually align widgets. The painted table is symmetric
  /// so no bias is needed.
  static double verticalBiasFromAngle(double angle) {
    return 0;
  }

  /// Returns the position of the player relative to the table center using
  /// simple elliptical geometry.
  static Offset positionForPlayer(
    int index,
    int numberOfPlayers,
    double tableWidth,
    double tableHeight,
  ) {
    final double angle = 2 * pi * index / numberOfPlayers + pi / 2;
    final double radiusX = tableWidth / 2;
    final double radiusY = tableHeight / 2;
    return Offset(radiusX * cos(angle), radiusY * sin(angle));
  }
}
