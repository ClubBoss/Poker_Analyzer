import 'dart:math';

import 'package:flutter/material.dart';

import '../session_player/models.dart';
import '../session_player/mvs_player.dart';

class ModulesScreen extends StatelessWidget {
  final List<UiSpot> spots;
  const ModulesScreen({super.key, required this.spots});

  List<UiSpot> _preflopCore() {
    const stacks = {'10bb', '20bb', '40bb', '100bb'};
    final res = <UiSpot>[];
    final perCell = <String, int>{};
    for (final s in spots) {
      if (s.kind != SpotKind.preflop) continue;
      if (!stacks.contains(s.stack)) continue;
      final key = '${s.pos}-${s.stack}';
      final c = perCell[key] ?? 0;
      if (c >= 2) continue;
      perCell[key] = c + 1;
      res.add(s);
      if (res.length >= 20) break;
    }
    return res;
  }

  List<UiSpot> _flopJam() {
    final res = <UiSpot>[];
    for (final s in spots) {
      if (s.kind != SpotKind.flop) continue;
      if (!s.stack.toLowerCase().contains('spr<3')) continue;
      res.add(s);
      if (res.length >= 20) break;
    }
    return res;
  }

  List<UiSpot> _mixed() {
    final list = List<UiSpot>.from(spots);
    list.shuffle(Random(0));
    return list.take(min(20, list.length)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modules')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Preflop Core'),
            subtitle: const Text('10/20/40/100bb × positions'),
            onTap: () {
              final subset = _preflopCore();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MvsSessionPlayer(
                      spots: subset, packId: 'mod:preflop'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Flop Jam'),
            subtitle: const Text('SPR<3'),
            onTap: () {
              final subset = _flopJam();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MvsSessionPlayer(
                      spots: subset, packId: 'mod:flopjam'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Mixed Drill'),
            subtitle: const Text('random 20 from current pool'),
            onTap: () {
              final subset = _mixed();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MvsSessionPlayer(spots: subset, packId: 'mod:mixed'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
