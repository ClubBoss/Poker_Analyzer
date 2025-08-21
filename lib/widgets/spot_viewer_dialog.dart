import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/v2/training_pack_spot.dart';
import '../core/training/engine/training_type_engine.dart';
import '../widgets/spot_quiz_widget.dart';
import '../widgets/action_history_widget.dart';
import '../models/action_entry.dart';
import '../services/training_session_service.dart';
import '../services/tag_service.dart';
import 'share_dialog.dart';
import '../screens/v2/training_pack_spot_editor_screen.dart';
import '../services/inline_theory_linker_service.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/theory_mini_lesson_navigator.dart';

class SpotViewerDialog extends StatefulWidget {
  final TrainingPackSpot spot;
  final BuildContext parentContext;
  final List<String> templateTags;
  final TrainingType trainingType;
  const SpotViewerDialog({
    super.key,
    required this.spot,
    required this.parentContext,
    this.templateTags = const [],
    this.trainingType = TrainingType.postflop,
  });

  @override
  State<SpotViewerDialog> createState() => _SpotViewerDialogState();
}

class _SpotViewerDialogState extends State<SpotViewerDialog> {
  late TrainingPackSpot spot;
  final _linker = InlineTheoryLinkerService();
  TheoryMiniLessonNode? _lesson;

  @override
  void initState() {
    super.initState();
    spot = widget.spot;
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final res = await _linker.findSuggestedLessonForSpot(spot);
    if (!mounted) return;
    setState(() => _lesson = res);
  }

  Map<int, String> _posMap() {
    return {
      for (int i = 0; i < spot.hand.playerCount; i++)
        i: i == spot.hand.heroIndex ? spot.hand.position.label : 'P${i + 1}',
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
            ...a.customLabel!.split(' '),
    ].join(' ');
    final lines = <String>[
      if (hero.isNotEmpty) 'Cards: $hero',
      if (board.isNotEmpty) 'Board: $board',
      'Position: $pos',
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
        backgroundColor: Colors.black.withValues(alpha: 0.8),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      final updated = spot.copyWith(
        note: result.trim(),
        editedAt: DateTime.now(),
      );
      await context.read<TrainingSessionService>().updateSpot(updated);
      setState(() => spot = updated);
    }
  }

  Future<void> _editTags() async {
    final tags = context.read<TagService>().tags;
    final selected = spot.tags.toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          title: const Text('Tags', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final tag in tags)
                  CheckboxListTile(
                    value: selected.contains(tag),
                    title: Text(
                      tag,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onChanged: (v) {
                      setStateDialog(() {
                        if (v ?? false) {
                          selected.add(tag);
                        } else {
                          selected.remove(tag);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected.toList()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      final updated = spot.copyWith(tags: result, editedAt: DateTime.now());
      await context.read<TrainingSessionService>().updateSpot(updated);
      if (!mounted) return;
      setState(() => spot = updated);
    }
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: spot.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spot ID copied to clipboard')),
    );
  }

  Widget _evCard() {
    final res = spot.evalResult;
    if (res == null) return const SizedBox.shrink();
    final ev = res.ev;
    final icm = res.icmEv;
    if (ev == null && icm == null) return const SizedBox.shrink();
    final rows = <Widget>[];
    if (ev != null) {
      rows.add(
        Text(
          'EV: ${ev >= 0 ? '+' : ''}${ev.toStringAsFixed(1)} BB',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    if (icm != null) {
      rows.add(
        Text(
          'ICM EV: ${icm >= 0 ? '+' : ''}${icm.toStringAsFixed(3)}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(spot.title.isEmpty ? 'Spot' : spot.title)),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'copy') _copyId();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copy', child: Text('Copy Spot ID')),
            ],
          ),
        ],
      ),
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
            ActionHistoryWidget(
              actions: _actions(),
              playerPositions: _posMap(),
            ),
            _evCard(),
            if (_lesson != null) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: Text(
                  _lesson!.title,
                  style: const TextStyle(color: Colors.white),
                ),
                textColor: Colors.white,
                collapsedTextColor: Colors.white,
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lesson!.content.trim().split(RegExp(r'\n\n+')).first,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => TheoryMiniLessonNavigator.instance
                                .openLessonById(_lesson!.id, context),
                            child: const Text('Read full'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _editNote, child: const Text('Edit')),
        TextButton(onPressed: _editTags, child: const Text('Edit Tags')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await Navigator.of(widget.parentContext).push(
              MaterialPageRoute(
                builder: (_) => TrainingPackSpotEditorScreen(
                  spot: spot,
                  templateTags: widget.templateTags,
                  trainingType: widget.trainingType,
                ),
              ),
            );
          },
          child: const Text('Edit Full'),
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

Future<void> showSpotViewerDialog(
  BuildContext context,
  TrainingPackSpot spot, {
  List<String> templateTags = const [],
  TrainingType trainingType = TrainingType.postflop,
}) {
  return showDialog(
    context: context,
    builder: (_) => SpotViewerDialog(
      spot: spot,
      parentContext: context,
      templateTags: templateTags,
      trainingType: trainingType,
    ),
  );
}
