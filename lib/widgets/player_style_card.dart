import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_style_service.dart';
import '../services/player_style_forecast_service.dart';

class PlayerStyleCard extends StatelessWidget {
  const PlayerStyleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<PlayerStyleService>().style;
    final forecast = context.watch<PlayerStyleForecastService>().forecast;
    String label;
    String hint;
    IconData icon;
    switch (style) {
      case PlayerStyle.aggressive:
        label = 'Агрессивный';
        hint = 'Сбавьте агрессию ранних улиц';
        icon = Icons.trending_down;
        break;
      case PlayerStyle.passive:
        label = 'Пассивный';
        hint = 'Проявите больше агрессии';
        icon = Icons.trending_up;
        break;
      case PlayerStyle.neutral:
        label = 'Нейтральный';
        hint = 'Сохраняйте баланс игры';
        icon = Icons.balance;
        break;
    }
    String forecastText;
    switch (forecast) {
      case PlayerStyle.aggressive:
        forecastText = 'Ожидается рост агрессии';
        break;
      case PlayerStyle.passive:
        forecastText = 'Ожидается снижение агрессии';
        break;
      case PlayerStyle.neutral:
        forecastText = 'Стиль стабилен';
        break;
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Стиль: $label',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(forecastText,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(hint, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
