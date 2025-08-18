import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poker_analyzer/ui/modules/cash_packs.dart';
import 'package:poker_analyzer/ui/modules/icm_bb_packs.dart';
import 'package:poker_analyzer/ui/modules/icm_mix_packs.dart';
import 'package:poker_analyzer/ui/modules/icm_packs.dart';
import 'package:poker_analyzer/ui/modules/icm_bubble_packs.dart';

import '../../services/spot_importer.dart';
import '../session_player/models.dart';
import '../session_player/mvs_player.dart';
import '../session_player/mini_toast.dart';

class ModulesScreen extends StatefulWidget {
  final List<UiSpot> spots;
  const ModulesScreen({super.key, required this.spots});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  List<UiSpot> _preflopCore() {
    const stacks = {'10bb', '20bb', '40bb', '100bb'};
    final res = <UiSpot>[];
    final perCell = <String, int>{};
    for (final s in widget.spots) {
      if (s.kind.name != 'callVsJam') continue;
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
    for (final s in widget.spots) {
      if (s.kind.name != 'l3_postflop_jam') continue;
      res.add(s);
      if (res.length >= 20) break;
    }
    return res;
  }

  List<UiSpot> _mixed() {
    final list = List<UiSpot>.from(widget.spots);
    list.shuffle(Random(0));
    return list.take(min(20, list.length)).toList();
  }

  Future<void> _pasteSpots() async {
    final data = await Clipboard.getData('text/plain');
    final content = data?.text?.trim();
    if (content == null || content.isEmpty) {
      showMiniToast(context, 'Clipboard is empty');
      return;
    }
    try {
      // Tolerant: 'json' also accepts JSON Lines via importer fallback.
      final report = SpotImporter.parse(content, format: 'json');
      final dupToast = report.skippedDuplicates > 0
          ? ', dups ${report.skippedDuplicates}'
          : '';
      showMiniToast(
        context,
        'Imported ${report.added} (skipped ${report.skipped}$dupToast)',
      );
      for (final e in report.errors) {
        showMiniToast(context, e);
      }
      if (report.spots.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MvsSessionPlayer(spots: report.spots, packId: 'import:clipboard'),
        ),
      );
    } catch (_) {
      showMiniToast(context, 'Import failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pre = _preflopCore();
    final flop = _flopJam();
    final mix = _mixed();
    return Scaffold(
      appBar: AppBar(title: const Text('Modules')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Start last import'),
                  onPressed: () {
                    if (widget.spots.isEmpty) {
                      showMiniToast(context, 'Import spots first');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MvsSessionPlayer(
                            spots: widget.spots,
                            packId: 'import:last',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('Start Cash L3'),
                  onPressed: () {
                    final spots = loadCashL3V1();
                    if (spots.isEmpty) {
                      showMiniToast(context, 'Pack is empty');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MvsSessionPlayer(
                            spots: spots,
                            packId: 'cash:l3:v1',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('Start ICM L4 SB'),
                  onPressed: () {
                    final spots = loadIcmL4SbV1();
                    if (spots.isEmpty) {
                      showMiniToast(context, 'Pack is empty');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MvsSessionPlayer(
                            spots: spots,
                            packId: 'icm:l4:sb:v1',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('Start ICM L4 BB'),
                  onPressed: () {
                    final spots = loadIcmL4BbV1();
                    if (spots.isEmpty) {
                      showMiniToast(context, 'Pack is empty');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MvsSessionPlayer(
                            spots: spots,
                            packId: 'icm:l4:bb:v1',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('Paste spots'),
                  onPressed: _pasteSpots,
                ),
                ActionChip(
                  label: const Text('Start ICM L4 Mix'),
                  onPressed: () {
                    final spots = loadIcmL4MixV1();
                    if (spots.isEmpty) {
                      showMiniToast(context, 'Pack is empty');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MvsSessionPlayer(
                            spots: spots,
                            packId: 'icm:l4:mix:v1',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  label: const Text('Start ICM L4 Bubble'),
                  onPressed: () {
                    final spots = loadIcmL4BubbleV1();
                    if (spots.isEmpty) {
                      showMiniToast(context, 'Pack is empty');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MvsSessionPlayer(
                            spots: spots,
                            packId: 'icm:l4:bubble:v1',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Preflop Core'),
            subtitle: const Text('10/20/40/100bb × positions'),
            trailing: Chip(label: Text('${pre.length} spots')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MvsSessionPlayer(spots: pre, packId: 'mod:preflop'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Flop Jam'),
            subtitle: const Text('SPR<3'),
            trailing: Chip(label: Text('${flop.length} spots')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MvsSessionPlayer(spots: flop, packId: 'mod:flopjam'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Mixed Drill'),
            subtitle: const Text('random 20 from current pool'),
            trailing: Chip(label: Text('${mix.length} spots')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MvsSessionPlayer(spots: mix, packId: 'mod:mixed'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
