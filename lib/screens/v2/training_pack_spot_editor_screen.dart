import 'package:flutter/material.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../helpers/training_pack_storage.dart';
import '../../helpers/title_utils.dart';
import '../../models/card_model.dart';
import '../../widgets/card_picker_widget.dart';
import '../../models/evaluation_result.dart';
import 'package:provider/provider.dart';
import '../../services/evaluation_executor_service.dart';

class TrainingPackSpotEditorScreen extends StatefulWidget {
  final TrainingPackSpot spot;
  const TrainingPackSpotEditorScreen({super.key, required this.spot});

  @override
  State<TrainingPackSpotEditorScreen> createState() => _TrainingPackSpotEditorScreenState();
}

class _TrainingPackSpotEditorScreenState extends State<TrainingPackSpotEditorScreen> {
  late final TextEditingController _titleCtr;
  late final TextEditingController _noteCtr;
  bool _loading = false;

  Set<String> _usedCards() {
    final hero = widget.spot.hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty);
    return {
      ...hero,
      ...widget.spot.hand.board,
    };
  }

  CardModel _toCard(String s) {
    return CardModel(rank: s[0], suit: s.substring(1));
  }

  void _setBoardCard(int index, CardModel card) {
    final b = widget.spot.hand.board;
    final v = '${card.rank}${card.suit}';
    setState(() {
      if (index < b.length) {
        b[index] = v;
      } else if (index == b.length) {
        b.add(v);
      }
    });
  }

  Widget _streetPicker(String label, int start, int count) {
    final b = widget.spot.hand.board;
    final end = (b.length - start).clamp(0, count);
    final cards = [for (int i = 0; i < end; i++) _toCard(b[start + i])];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CardPickerWidget(
          cards: cards,
          count: count,
          onChanged: (i, c) => _setBoardCard(start + i, c),
          disabledCards: _usedCards(),
        ),
      ],
    );
  }

  Widget _evPreviewBox() {
    final EvaluationResult? res = widget.spot.evalResult;
    final bg = Colors.grey.shade800;
    if (res == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Text('EV Preview',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
            Spacer(),
            Text('Not evaluated', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    final ev = (res.expectedEquity * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('EV Preview',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          const Spacer(),
          Text('$ev%', style: const TextStyle(color: Colors.greenAccent)),
          const SizedBox(width: 8),
          Text(res.expectedAction,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _addTagDialog() async {
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (tag != null && tag.isNotEmpty) {
      setState(() => widget.spot.tags.add(tag));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.spot.title = normalizeSpotTitle(widget.spot.title);
    _titleCtr = TextEditingController(text: widget.spot.title);
    _noteCtr = TextEditingController(text: widget.spot.note);
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _noteCtr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final normalized = normalizeSpotTitle(_titleCtr.text);
    widget.spot.title = normalized;
    _titleCtr.text = normalized;
    if (widget.spot.title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    widget.spot.editedAt = DateTime.now();
    final templates = await TrainingPackStorage.load();
    for (final t in templates) {
      for (var i = 0; i < t.spots.length; i++) {
        if (t.spots[i].id == widget.spot.id) {
          t.spots[i] = widget.spot;
        }
      }
    }
    await TrainingPackStorage.save(templates);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _evaluate() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<EvaluationExecutorService>().evaluate(widget.spot);
      setState(() => widget.spot.evalResult = res);
      final ev = (res.expectedEquity * 100).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('EV $ev% ${res.expectedAction}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Evaluation failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit spot'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtr,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
              onChanged: (v) => setState(() => widget.spot.title = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtr,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 5,
              onChanged: (v) => setState(() => widget.spot.note = v),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in widget.spot.tags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () => setState(() => widget.spot.tags.remove(tag)),
                  ),
                InputChip(
                  label: const Text('+ Add'),
                  onPressed: _addTagDialog,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _streetPicker('Flop', 0, 3),
            const SizedBox(height: 16),
            _streetPicker('Turn', 3, 1),
            const SizedBox(height: 16),
            _streetPicker('River', 4, 1),
            const SizedBox(height: 16),
            _evPreviewBox(),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _evaluate,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Evaluate'),
            ),
          ],
        ),
      ),
    );
  }
}
