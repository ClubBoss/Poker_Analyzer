import 'package:flutter/material.dart';

import 'tag_decay_forecast_service.dart';

class DecayHeatmapTile {
  final String tag;
  final double urgency; // 0.0 = fresh, 1.0 = decayed
  final Color color;

  DecayHeatmapTile({
    required this.tag,
    required this.urgency,
    required this.color,
  });
}

class DecayHeatmapTileGenerator {
  final TagDecayForecastService service;

  DecayHeatmapTileGenerator({this.service = const TagDecayForecastService()});

  Color _colorForUrgency(double u) {
    if (u <= 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, u * 2) ?? Colors.green;
    }
    return Color.lerp(Colors.yellow, Colors.red, (u - 0.5) * 2) ?? Colors.red;
  }

  Future<List<DecayHeatmapTile>> generate() async {
    final forecasts = await service.getAllForecasts();
    final result = <DecayHeatmapTile>[];
    for (final entry in forecasts.entries) {
      final urgency = entry.value.clamp(0.0, 1.0);
      result.add(
        DecayHeatmapTile(
          tag: entry.key,
          urgency: urgency,
          color: _colorForUrgency(urgency),
        ),
      );
    }
    return result;
  }
}
