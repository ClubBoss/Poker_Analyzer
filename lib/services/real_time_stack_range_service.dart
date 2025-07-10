import 'package:flutter/foundation.dart';
import 'player_style_forecast_service.dart';
import 'player_style_service.dart';
import 'pack_generator_service.dart';

class RealTimeStackRangeService extends ChangeNotifier {
  final PlayerStyleForecastService forecast;
  RealTimeStackRangeService({required this.forecast}) {
    _update();
    forecast.addListener(_update);
  }

  int stack = 10;
  List<String> range = [];

  void _update() {
    int diff;
    switch (forecast.forecast) {
      case PlayerStyle.aggressive:
        diff = -2;
        break;
      case PlayerStyle.passive:
        diff = 2;
        break;
      default:
        diff = 0;
    }
    stack = (10 + diff).clamp(5, 40);
    var pct = 25 + diff * 5;
    pct = pct.clamp(5, 100);
    range = PackGeneratorService.topNHands(pct).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    forecast.removeListener(_update);
    super.dispose();
  }
}
