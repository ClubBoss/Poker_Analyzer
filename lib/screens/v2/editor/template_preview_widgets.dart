import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TemplateSummaryPanel extends StatelessWidget {
  final int spots;
  final int evCount;
  final int icmCount;
  final List<String> tags;
  final double? avgEv;
  const TemplateSummaryPanel({
    super.key,
    required this.spots,
    required this.evCount,
    required this.icmCount,
    required this.tags,
    required this.avgEv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spots: $spots', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Builder(
            builder: (_) {
              final evPct = spots == 0 ? 0 : (evCount / spots * 100).round();
              final icmPct = spots == 0 ? 0 : (icmCount / spots * 100).round();
              final off = MediaQuery.of(context).padding.top;
              return Row(
                children: [
                  Tooltip(
                    message: _evTooltip,
                    waitDuration: const Duration(milliseconds: 300),
                    preferBelow: false,
                    preferAbove: false,
                    verticalOffset: off,
                    child: Semantics(
                      label: _evTooltip,
                      child: Text(
                        'EV: $evCount/$spots ($evPct%)',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: Colors.white70)),
                  Tooltip(
                    message: _icmTooltip,
                    waitDuration: const Duration(milliseconds: 300),
                    preferBelow: false,
                    preferAbove: false,
                    verticalOffset: off,
                    child: Semantics(
                      label: _icmTooltip,
                      child: Text(
                        'ICM: $icmCount/$spots ($icmPct%)',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final t in tags)
                    Chip(
                      backgroundColor: Colors.grey[800],
                      label: Text(
                        t,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          if (avgEv != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Avg EV: ${(avgEv! >= 0 ? '+' : '')}${avgEv!.toStringAsFixed(2)} BB',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

const _evTooltip = 'Spots with EV values';
const _icmTooltip = 'Spots with ICM values';

class RangeLegend extends StatelessWidget {
  const RangeLegend({super.key});

  Widget _item(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _item(Colors.orange, 'Pairs'),
        const SizedBox(width: 12),
        _item(Colors.green, 'Suited'),
        const SizedBox(width: 12),
        _item(Colors.blue, 'Offsuit'),
      ],
    );
  }
}

class MatrixPickerPage extends StatefulWidget {
  final Set<String> initial;
  const MatrixPickerPage({super.key, required this.initial});

  @override
  State<MatrixPickerPage> createState() => _MatrixPickerPageState();
}

class _MatrixPickerPageState extends State<MatrixPickerPage> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 13,
      children: [
        for (final h in _hands)
          GestureDetector(
            onTap: () => setState(() {
              _selected.contains(h) ? _selected.remove(h) : _selected.add(h);
            }),
            child: Container(
              margin: const EdgeInsets.all(2),
              color: _selected.contains(h) ? Colors.blue : Colors.grey[800],
              child: Center(
                child: Text(
                  h,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

const _hands = [
  'AA',
  'KK',
  'QQ',
  'JJ',
  'TT',
  '99',
  '88',
  '77',
  '66',
  '55',
  '44',
  '33',
  '22',
];

class DragAutoScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  const DragAutoScroll({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<DragAutoScroll> createState() => _DragAutoScrollState();
}

class _DragAutoScrollState extends State<DragAutoScroll> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (n) {
        final p = n.metrics.pixels;
        if (p < 50) {
          widget.controller.jumpTo(p - 20);
        } else if (p > n.metrics.maxScrollExtent - 50) {
          widget.controller.jumpTo(p + 20);
        }
        return true;
      },
      child: widget.child,
    );
  }
}
