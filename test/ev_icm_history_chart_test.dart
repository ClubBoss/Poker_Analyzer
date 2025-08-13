import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/ev_icm_history_chart.dart';
import 'package:poker_analyzer/widgets/common/animated_line_chart.dart';
import 'package:poker_analyzer/services/progress_forecast_service.dart';
import 'package:poker_analyzer/services/saved_hand_manager_service.dart';
import 'package:poker_analyzer/services/saved_hand_storage_service.dart';
import 'package:poker_analyzer/services/player_style_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeService extends ProgressForecastService {
  final List<MapEntry<DateTime, double>> _ev;
  final List<MapEntry<DateTime, double>> _icm;
  final List<MapEntry<DateTime, double>> _acc;
  _FakeService(this._ev, this._icm, this._acc)
      : super(
            hands: SavedHandManagerService(storage: SavedHandStorageService()),
            style: PlayerStyleService(
                hands: SavedHandManagerService(
                    storage: SavedHandStorageService())));
  @override
  List<MapEntry<DateTime, double>> get evSeries => _ev;
  @override
  List<MapEntry<DateTime, double>> get icmSeries => _icm;
  @override
  List<MapEntry<DateTime, double>> get accuracySeries => _acc;
  @override
  List<ProgressEntry> get history => const [];
  @override
  Iterable<String> get positions => const [];
  @override
  Iterable<String> get tags => const [];
  @override
  ProgressForecast get forecast =>
      const ProgressForecast(accuracy: 0, ev: 0, icm: 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('chart shows 3 data series', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = _FakeService(
        [const MapEntry(DateTime(2023, 1, 1), 1.0)],
        [const MapEntry(DateTime(2023, 1, 1), 2.0)],
        [const MapEntry(DateTime(2023, 1, 1), 0.5)]);
    await tester.pumpWidget(
      ChangeNotifierProvider<ProgressForecastService>.value(
        value: service,
        child: const MaterialApp(home: EvIcmHistoryChart()),
      ),
    );
    final chart =
        tester.widget<AnimatedLineChart>(find.byType(AnimatedLineChart));
    expect(chart.data.lineBarsData.length, 3);
  });
}
