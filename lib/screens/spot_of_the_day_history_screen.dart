import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_spot.dart';
import '../services/spot_of_the_day_service.dart';
import '../screens/training_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/sync_status_widget.dart';

class SpotOfTheDayHistoryScreen extends StatefulWidget {
  const SpotOfTheDayHistoryScreen({super.key});

  @override
  State<SpotOfTheDayHistoryScreen> createState() =>
      _SpotOfTheDayHistoryScreenState();
}

class _SpotOfTheDayHistoryScreenState extends State<SpotOfTheDayHistoryScreen> {
  late Future<List<TrainingSpot>> _spotsFuture;

  @override
  void initState() {
    super.initState();
    final service = context.read<SpotOfTheDayService>();
    _spotsFuture = service.loadAllSpots();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM', Intl.getCurrentLocale()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SpotOfTheDayService>();
    final history = List.of(service.history)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('История "Спот дня"'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: FutureBuilder<List<TrainingSpot>>(
        future: _spotsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final spots = snapshot.data!;
          if (history.isEmpty) {
            return const Center(child: Text('История пуста'));
          }
          return ListView.separated(
            itemCount: history.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final entry = history[index];
              final spot = entry.spotIndex < spots.length
                  ? spots[entry.spotIndex]
                  : null;
              final pos = spot != null && spot.heroIndex < spot.positions.length
                  ? spot.positions[spot.heroIndex]
                  : '-';
              final icon = entry.correct == true
                  ? Icons.check_circle
                  : entry.correct == false
                      ? Icons.cancel
                      : Icons.remove;
              final color = entry.correct == true
                  ? Colors.green
                  : entry.correct == false
                      ? Colors.red
                      : Colors.grey;
              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(_formatDate(entry.date),
                    style: const TextStyle(color: Colors.white)),
                subtitle:
                    Text(pos, style: const TextStyle(color: Colors.white70)),
                onTap: spot == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TrainingScreen(spot: spot)),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}
