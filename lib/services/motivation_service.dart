import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class MotivationService {
  MotivationService._();
  static const _quoteKey = 'daily_quote';
  static const _dateKey = 'daily_quote_date';
  static const _quotes = [
    'Keep pushing forward!',
    'Every hand is a lesson.',
    'Stay focused and grind.',
    'Believe in your reads.',
    'Small edges build bankrolls.',
  ];

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Future<String> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_dateKey);
    final quote = prefs.getString(_quoteKey);
    final now = DateTime.now();
    if (dateStr != null && quote != null) {
      final date = DateTime.tryParse(dateStr);
      if (date != null && _sameDay(date, now)) return quote;
    }
    final q = _quotes[Random().nextInt(_quotes.length)];
    await prefs.setString(_quoteKey, q);
    await prefs.setString(_dateKey, now.toIso8601String());
    return q;
  }
}
