import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/progress_forecast_service.dart';

class ProgressForecastCard extends StatelessWidget {
  const ProgressForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    final forecast = context.watch<ProgressForecastService>().forecast;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Прогноз следующей сессии',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Acc', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      '${(forecast.accuracy * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('EV', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      forecast.ev.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('ICM', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      forecast.icm.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
