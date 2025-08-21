import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/progress_forecast_service.dart';
import '../widgets/ev_icm_series_chart.dart';
import '../widgets/sync_status_widget.dart';

class PositionTagAnalyticsScreen extends StatefulWidget {
  static const route = '/position_tag_analytics';
  const PositionTagAnalyticsScreen({super.key});

  @override
  State<PositionTagAnalyticsScreen> createState() =>
      _PositionTagAnalyticsScreenState();
}

class _PositionTagAnalyticsScreenState
    extends State<PositionTagAnalyticsScreen> {
  bool _byTag = false;
  String? _current;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ProgressForecastService>();
    final values = _byTag ? service.tags : service.positions;
    if (_current == null || !values.contains(_current)) {
      _current = values.isNotEmpty ? values.first : null;
    }
    final data = _byTag
        ? (_current != null
            ? service.tagSeries(_current!)
            : const <ProgressEntry>[])
        : (_current != null
            ? service.positionSeries(_current!)
            : const <ProgressEntry>[]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Position & Tag'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              DropdownButton<bool>(
                value: _byTag,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: false, child: Text('Position')),
                  DropdownMenuItem(value: true, child: Text('Tag')),
                ],
                onChanged: (v) => setState(() => _byTag = v ?? false),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _current,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                items: [
                  for (final v in values)
                    DropdownMenuItem(value: v, child: Text(v)),
                ],
                onChanged: (v) => setState(() => _current = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          EvIcmSeriesChart(data: data),
        ],
      ),
    );
  }
}
