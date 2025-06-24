import 'package:flutter/material.dart';

enum MistakeSeverity { high, medium, low }

extension MistakeSeverityColor on MistakeSeverity {
  Color get color {
    switch (this) {
      case MistakeSeverity.high:
        return Colors.redAccent;
      case MistakeSeverity.medium:
        return Colors.orangeAccent;
      case MistakeSeverity.low:
      default:
        return Colors.greenAccent;
    }
  }
}

extension MistakeSeverityText on MistakeSeverity {
  String get label {
    switch (this) {
      case MistakeSeverity.high:
        return 'Критичный';
      case MistakeSeverity.medium:
        return 'Средний';
      case MistakeSeverity.low:
      default:
        return 'Лёгкий';
    }
  }
}
