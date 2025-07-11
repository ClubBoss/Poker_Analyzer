import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/progress_forecast_service.dart';

class DynamicProgressRow extends StatelessWidget {
  const DynamicProgressRow({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ProgressForecastService>();
    final hist = service.history;
    final forecast = service.forecast;
    double lastAcc = forecast.accuracy;
    double prevAcc = lastAcc;
    double lastEv = forecast.ev;
    double prevEv = lastEv;
    double lastIcm = forecast.icm;
    double prevIcm = lastIcm;
    if (hist.length >= 2) {
      lastAcc = hist.last.accuracy;
      prevAcc = hist[hist.length - 2].accuracy;
      lastEv = hist.last.ev;
      prevEv = hist[hist.length - 2].ev;
      lastIcm = hist.last.icm;
      prevIcm = hist[hist.length - 2].icm;
    }
    final accUp = lastAcc >= prevAcc;
    final evUp = lastEv >= prevEv;
    final icmUp = lastIcm >= prevIcm;
    Widget item(String label, double value, bool up) {
      final color = up ? Colors.greenAccent : Colors.redAccent;
      final icon = up ? Icons.trending_up : Icons.trending_down;
      return Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label == 'Acc'
                      ? '${(value * 100).toStringAsFixed(1)}%'
                      : value.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          item('Acc', forecast.accuracy, accUp),
          item('EV', forecast.ev, evUp),
          item('ICM', forecast.icm, icmUp),
        ],
      ),
    );
  }
}
