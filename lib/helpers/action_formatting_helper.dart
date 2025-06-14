import 'package:flutter/material.dart';

import '../models/action_entry.dart';

/// Utility methods for formatting poker actions and related data.
class ActionFormattingHelper {
  /// Formats [amount] with spaces as thousand separators.
  static String formatAmount(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Returns a color representing the given [action].
  static Color actionColor(String action) {
    switch (action) {
      case 'fold':
        return Colors.red[700]!;
      case 'call':
        return Colors.blue[700]!;
      case 'raise':
        return Colors.green[600]!;
      case 'bet':
        return Colors.amber[700]!;
      case 'all-in':
        return Colors.purpleAccent;
      case 'check':
        return Colors.grey[700]!;
      default:
        return Colors.black;
    }
  }

  /// Returns the text color for the given [action].
  static Color actionTextColor(String action) {
    switch (action) {
      case 'bet':
        return Colors.black;
      default:
        return Colors.white;
    }
  }

  /// Returns an icon representing the given [action], if any.
  static IconData? actionIcon(String action) {
    switch (action) {
      case 'fold':
        return Icons.close;
      case 'call':
        return Icons.call;
      case 'raise':
        return Icons.arrow_upward;
      case 'bet':
        return Icons.trending_up;
      case 'all-in':
        return Icons.flash_on;
      case 'check':
        return Icons.remove;
      default:
        return null;
    }
  }

  /// Formats the last action label for display.
  static String formatLastAction(ActionEntry entry) {
    final a = entry.action;
    final cap = a.isNotEmpty ? a[0].toUpperCase() + a.substring(1) : a;
    return entry.amount != null ? '$cap ${entry.amount}' : cap;
  }
}
