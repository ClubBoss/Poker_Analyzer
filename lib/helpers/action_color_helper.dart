import 'package:flutter/material.dart';

Color actionColor(String action) {
  switch (action) {
    case 'fold':
      return Colors.red;
    case 'call':
      return Colors.blue;
    case 'raise':
    case 'bet':
      return Colors.green;
    case 'check':
      return Colors.grey;
    case 'custom':
      return Colors.purple;
    default:
      return Colors.white;
  }
}
