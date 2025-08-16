import 'package:flutter/material.dart';
import '../session_player/models.dart';
import '../session_player/mvs_player.dart';
import '../session_player/mini_toast.dart';

class CoverageDashboard extends StatefulWidget {
  final List<UiSpot> spots;
  const CoverageDashboard({super.key, required this.spots});

  @override
  State<CoverageDashboard> createState() => _CoverageDashboardState();
}

class _CoverageDashboardState extends State<CoverageDashboard> {
  bool showPreflop = true;
  bool showPostflop = true;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.spots.where((spot) {
      final isPost = spot.kind.name.startsWith('l3_');
      if (isPost) return showPostflop;
      return showPreflop;
    }).toList();

    const positions = ['SB', 'BB', 'UTG', 'MP', 'CO', 'BTN'];
    const stacks = [10, 20, 40, 100];
    final grid = {
      for (final p in positions) p: {for (final s in stacks) s: 0}
    };
    int other = 0;
    int preflop = 0;
    int postflop = 0;
    for (final spot in filtered) {
      final name = spot.kind.name;
      if (name.startsWith('l3_')) {
        postflop++;
      } else {
        preflop++;
      }
      final m = RegExp(r'\d+').firstMatch(spot.stack);
      final stack = m == null ? null : int.tryParse(m.group(0)!);
      if (stack != null &&
          stacks.contains(stack) &&
          positions.contains(spot.pos)) {
        grid[spot.pos]![stack] = grid[spot.pos]![stack]! + 1;
      } else {
        other++;
      }
    }
    final total = filtered.length;
    final target = showPreflop && showPostflop
        ? 48
        : (showPreflop || showPostflop ? 24 : 0);
    final coverage =
        target == 0 ? 0 : ((total / target) * 100).clamp(0, 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Coverage')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('$total spots, $total/$target -> $coverage%'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Preflop'),
                    selected: showPreflop,
                    onSelected: (v) => setState(() => showPreflop = v),
                  ),
                  ChoiceChip(
                    label: const Text('Postflop'),
                    selected: showPostflop,
                    onSelected: (v) => setState(() => showPostflop = v),
                  ),
                ],
              ),
            ),
            Table(
              border: TableBorder.all(),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    for (final s in stacks)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text('$s'),
                      ),
                  ],
                ),
                for (final p in positions)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(p),
                      ),
                      for (final s in stacks)
                        InkWell(
                          onTap: () {
                            final subset = filtered.where((spot) {
                              final m = RegExp(r'\d+').firstMatch(spot.stack);
                              final stack =
                                  m == null ? null : int.tryParse(m.group(0)!);
                              return spot.pos == p && stack == s;
                            }).toList();
                            if (subset.isEmpty) {
                              showMiniToast(context, 'No spots for $p/$s');
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MvsSessionPlayer(
                                    spots: subset,
                                    packId: 'cov:$p:$s',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text('${grid[p]![s]}'),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (other > 0)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('other stacks: $other',
                    style: const TextStyle(fontSize: 12)),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('preflop: $preflop  postflop: $postflop',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
