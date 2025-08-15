import 'package:flutter/material.dart';

import '../session_player/models.dart';
import '../session_player/mvs_player.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final acc = (entry['acc'] ?? 0) as num;
    final correct = entry['correct'] ?? 0;
    final total = entry['total'] ?? 0;
    final ts = entry['ts']?.toString() ?? '';
    final dt = DateTime.tryParse(ts)?.toLocal();
    final dateStr = dt?.toString() ?? ts;

    final rawSpots = entry['spots'];
    final spots = <UiSpot>[];
    if (rawSpots is List) {
      for (final e in rawSpots) {
        if (e is Map<String, dynamic>) {
          final k = e['k'];
          final h = e['h'];
          final p = e['p'];
          final st = e['s'];
          final act = e['a'];
          if (k is int && h is String && p is String && st is String && act is String) {
            spots.add(UiSpot(
              kind: SpotKind.values[k],
              hand: h,
              pos: p,
              stack: st,
              action: act,
              vsPos: e['v'] as String?,
              limpers: e['l'] as String?,
              explain: e['e'] as String?,
            ));
          }
        }
      }
    }

    final rawWrong = entry['wrongIdx'];
    final wrongIdx = <int>[];
    if (rawWrong is List) {
      for (final w in rawWrong) {
        if (w is int) wrongIdx.add(w);
      }
    }
    final wrongOnly = wrongIdx.isEmpty
        ? spots
        : [
            for (final i in wrongIdx)
              if (i >= 0 && i < spots.length) spots[i]
          ];

    final canReplay = spots.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: const Text('Date'),
            subtitle: Text(dateStr),
          ),
          ListTile(
            title: const Text('Accuracy'),
            subtitle: Text('${(acc * 100).toStringAsFixed(0)}%'),
          ),
          ListTile(
            title: const Text('Correct / Total'),
            subtitle: Text('$correct / $total'),
          ),
          const Spacer(),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: canReplay
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                Scaffold(body: MvsSessionPlayer(spots: wrongOnly)),
                          ),
                        );
                      }
                    : null,
                child: const Text('Replay errors'),
              ),
              ElevatedButton(
                onPressed: canReplay
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                Scaffold(body: MvsSessionPlayer(spots: spots)),
                          ),
                        );
                      }
                    : null,
                child: const Text('Replay all'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
