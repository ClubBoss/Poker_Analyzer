import 'package:flutter/material.dart';

String _toHex(int value) =>
    value.toRadixString(16).padLeft(2, '0').toUpperCase();

String colorToHex(Color c) =>
    '#${_toHex(c.red)}${_toHex(c.green)}${_toHex(c.blue)}';

Color colorFromHex(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return const Color(0xFF2196F3);
  return Color(int.parse('FF$h', radix: 16));
}
