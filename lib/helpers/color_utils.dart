import 'package:flutter/material.dart';

String colorToHex(Color c) =>
    '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

Color colorFromHex(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return const Color(0xFF2196F3);
  return Color(int.parse('FF$h', radix: 16));
}

