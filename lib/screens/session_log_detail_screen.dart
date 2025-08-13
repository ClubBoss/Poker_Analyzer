import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helpers/training_pack_storage.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_session.dart';

class SessionDetailScreen extends StatefulWidget {
  final String logId;
  const SessionDetailScreen({super.key, required this.logId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late Future<List<TrainingPackSpot>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TrainingPackSpot>> _load() async {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.initFlutter();
      await Hive.openBox('sessions');
    }
    final box = Hive.box('sessions');
    final raw = box.get(widget.logId);
    if (raw is Map) {
      final session = TrainingSession.fromJson(Map<String, dynamic>.from(raw));
      final templates = await TrainingPackStorage.load();
      final template =
          templates.firstWhereOrNull((t) => t.id == session.templateId);
      if (template != null) {
        final mistakes = <TrainingPackSpot>[];
        for (final spot in template.spots) {
          if (session.results[spot.id] == false) {
            mistakes.add(spot);
          }
        }
        return mistakes;
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: FutureBuilder<List<TrainingPackSpot>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final spots = snapshot.data ?? [];
          if (spots.isEmpty) {
            return const Center(
              child: Text('No hands', style: TextStyle(color: Colors.white70)),
            );
          }
          return ListView.builder(
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final s = spots[index];
              final cards = s.hand.heroCards;
              final tag = s.tags.firstWhereOrNull((t) => t.startsWith('cat:'));
              final tagText = tag != null ? tag.substring(4) : '—';
              final ev = s.heroEv ?? s.evalResult?.ev;
              final evText = ev != null ? ev.toStringAsFixed(1) : '—';
              return Card(
                color: const Color(0xFF2A2B2D),
                child: ListTile(
                  title: Text(
                    cards.isNotEmpty ? cards : s.id,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Tag: $tagText · EV $evText',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
