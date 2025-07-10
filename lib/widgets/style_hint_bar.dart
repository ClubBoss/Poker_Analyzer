import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_style_service.dart';
import '../services/player_style_forecast_service.dart';

class StyleHintBar extends StatelessWidget {
  const StyleHintBar({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<PlayerStyleService>().style;
    final forecast = context.watch<PlayerStyleForecastService>().forecast;
    String hint;
    switch (forecast) {
      case PlayerStyle.aggressive:
        hint = 'Снизьте агрессию на ранних улицах';
        break;
      case PlayerStyle.passive:
        hint = 'Увеличьте агрессию на поздних улицах';
        break;
      default:
        hint = 'Сохраняйте баланс агрессии';
    }
    IconData icon;
    switch (style) {
      case PlayerStyle.aggressive:
        icon = Icons.trending_down;
        break;
      case PlayerStyle.passive:
        icon = Icons.trending_up;
        break;
      default:
        icon = Icons.balance;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(hint, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
