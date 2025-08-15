import 'package:flutter/material.dart';

import 'mistakes_loader.dart';
import 'models.dart';
import 'mvs_player.dart';

class QuickMistakesPlayPage extends StatefulWidget {
  final String logsDir;
  const QuickMistakesPlayPage({super.key, this.logsDir = 'out/session_logs'});

  @override
  State<QuickMistakesPlayPage> createState() => _QuickMistakesPlayPageState();
}

class _QuickMistakesPlayPageState extends State<QuickMistakesPlayPage> {
  late Future<List<UiSpot>> _future;

  @override
  void initState() {
    super.initState();
    _future = loadMistakeSpotsFromLogs(dir: widget.logsDir);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mistakes quick play')),
      body: FutureBuilder<List<UiSpot>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final spots = snap.data ?? [];
          if (spots.isEmpty) {
            return const Center(child: Text('No mistakes found'));
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mistakes: ${spots.length}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            Scaffold(body: MvsSessionPlayer(spots: spots)),
                      ),
                    );
                  },
                  child: const Text('Play mistakes deck'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
