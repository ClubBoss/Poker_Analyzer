import 'dart:math';
import 'package:flutter/material.dart';

Offset getSeatPosition(int totalPlayers, int seatIndex,
    {required Size tableSize}) {
  // Центр стола
  final Offset center = Offset(tableSize.width / 2, tableSize.height / 2);

  // Относительные радиусы
  const double radiusX = 0.43;
  const double radiusY = 0.43;

  // Смещение угла: 0-й игрок ("Вы") будет внизу
  const double angleOffset = -pi / 2;

  // Угол для текущего игрока
  final double angle = (2 * pi * seatIndex / totalPlayers) + angleOffset;

  final double dx = center.dx + tableSize.width * radiusX * cos(angle);
  final double dy = center.dy + tableSize.height * radiusY * sin(angle);

  return Offset(dx, dy);
}
