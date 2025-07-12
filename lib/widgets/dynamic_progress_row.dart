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
    double prevAcc = forecast.accuracy;
    double lastAcc = forecast.accuracy;
    double prevEv = forecast.ev;
    double lastEv = forecast.ev;
    double prevIcm = forecast.icm;
    double lastIcm = forecast.icm;
    if (hist.length >= 2) {
      prevAcc = hist[hist.length - 2].accuracy;
      lastAcc = hist.last.accuracy;
      prevEv = hist[hist.length - 2].ev;
      lastEv = hist.last.ev;
      prevIcm = hist[hist.length - 2].icm;
      lastIcm = hist.last.icm;
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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label == 'Acc'
                        ? '${(v * 100).toStringAsFixed(1)}%'
                        : v.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
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
