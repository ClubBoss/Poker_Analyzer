import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2/training_pack_spot.dart';
import '../widgets/spot_quiz_widget.dart';
import '../widgets/action_history_widget.dart';
import '../models/action_entry.dart';
import '../services/training_session_service.dart';
import 'share_dialog.dart';

class SpotViewerDialog extends StatefulWidget {
  final TrainingPackSpot spot;
  const SpotViewerDialog({super.key, required this.spot});

  @override
  State<SpotViewerDialog> createState() => _SpotViewerDialogState();
}

class _SpotViewerDialogState extends State<SpotViewerDialog> {
  late TrainingPackSpot spot;

  @override
  void initState() {
    super.initState();
    spot = widget.spot;
  }

  Map<int, String> _posMap() {
    return {
      for (int i = 0; i < spot.hand.playerCount; i++)
        i: i == spot.hand.heroIndex ? spot.hand.position.label : 'P${i + 1}'
    };
  }

  List<ActionEntry> _actions() {
    final list = <ActionEntry>[];
    for (int s = 0; s < 4; s++) {
      list.addAll(spot.hand.actions[s] ?? []);
    }
    return list;
  }

  String _summary() {
    final map = _posMap();
    final hero = spot.hand.heroCards;
    final pos = spot.hand.position.label;
    final board = [
      for (final street in [1, 2, 3])
        for (final a in spot.hand.actions[street] ?? [])
          if (a.action == 'board' && a.customLabel?.isNotEmpty == true)
            ...a.customLabel!.split(' ')
    ].join(' ');
    final lines = <String>[
      if (hero.isNotEmpty) 'Cards: $hero',
      if (board.isNotEmpty) 'Board: $board',
      'Position: $pos'
    ];
    const names = ['Preflop', 'Flop', 'Turn', 'River'];
    for (int s = 0; s < 4; s++) {
      final acts = _actions()
          .where((a) => a.street == s && a.action != 'board' && !a.generated)
          .toList();
      if (acts.isEmpty) continue;
      lines.add('${names[s]}:');
      for (final a in acts) {
        final posName = map[a.playerIndex] ?? 'P${a.playerIndex + 1}';
        final label =
            a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action;
        final amount = a.amount != null ? ' ${a.amount}' : '';
        lines.add('  $posName $label$amount');
      }
    }
    if (spot.note.isNotEmpty) lines.add('Note: ${spot.note}');
    if (spot.tags.isNotEmpty) lines.add('Tags: ${spot.tags.join(', ')}');
    return lines.join('\n');
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: spot.note);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text('Note', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: 'Enter notes',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      final updated = spot.copyWith(note: result.trim());
      await context.read<TrainingSessionService>().updateSpot(updated);
      setState(() => spot = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(spot.title.isEmpty ? 'Spot' : spot.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpotQuizWidget(spot: spot),
            if (spot.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(spot.note, style: const TextStyle(color: Colors.white70)),
            ],
            if (spot.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [for (final t in spot.tags) Chip(label: Text(t))],
              ),
            ],
            const SizedBox(height: 8),
            ActionHistoryWidget(actions: _actions(), playerPositions: _posMap()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _editNote,
          child: const Text('Edit'),
        ),
        TextButton(
          onPressed: () => showShareDialog(context, _summary()),
          child: const Text('Share'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<void> showSpotViewerDialog(BuildContext context, TrainingPackSpot spot) {
  return showDialog(
    context: context,
    builder: (_) => SpotViewerDialog(spot: spot),
  );
}
