import 'package:flutter/material.dart';

Color colorFromHex(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

String colorToHex(Color color) {
  final String hex = color.value.toRadixString(16).padLeft(8, '0');
  return '#${hex.substring(2).toUpperCase()}';
}
