import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/training_spot.dart';

/// Provides a single [TrainingSpot] to highlight each day.
class TrainingSpotOfDayService {
  TrainingSpotOfDayService();

  /// Loads a spot from bundled assets based on the current day.
  Future<TrainingSpot?> getSpot() async {
    try {
      final data = await rootBundle.loadString('assets/spots/spots.json');
      final list = jsonDecode(data);
      if (list is List && list.isNotEmpty) {
        final dayIndex = DateTime.now().difference(DateTime(2020)).inDays;
        final index = dayIndex % list.length;
        final map = Map<String, dynamic>.from(list[index] as Map);
        return TrainingSpot.fromJson(map);
      }
    } catch (_) {}
    return null;
  }
}
