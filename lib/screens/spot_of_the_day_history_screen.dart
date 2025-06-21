import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_spot.dart';
import '../services/spot_of_the_day_service.dart';

class SpotOfTheDayHistoryScreen extends StatefulWidget {
  const SpotOfTheDayHistoryScreen({super.key});

  @override
  State<SpotOfTheDayHistoryScreen> createState() => _SpotOfTheDayHistoryScreenState();
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
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
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
              final board = spot != null
                  ? spot.boardCards.map((c) => c.toString()).join(' ')
                  : 'N/A';
              final positions = spot != null ? spot.positions.join(', ') : 'N/A';
              final stacks = spot != null
                  ? spot.stacks.map((s) => '$s').join(', ')
                  : 'N/A';
              return ListTile(
                title: Text(_formatDate(entry.date),
                    style: const TextStyle(color: Colors.white)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Доска: $board',
                        style: const TextStyle(color: Colors.white70)),
                    Text('Позиции: $positions',
                        style: const TextStyle(color: Colors.white70)),
                    Text('Стэки: $stacks',
                        style: const TextStyle(color: Colors.white70)),
                    Text(
                        'Ваш ответ: ${entry.userAction ?? '-'} \u2022 Реком.: ${entry.recommendedAction ?? '-'}',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
