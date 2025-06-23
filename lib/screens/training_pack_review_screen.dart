import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../models/training_pack.dart';
import '../models/saved_hand.dart';
import '../models/training_spot.dart';
import '../widgets/replay_spot_widget.dart';
import '../theme/app_colors.dart';
import '../services/tag_service.dart';
import '../services/training_pack_storage_service.dart';

/// Displays all spots from [pack] with option to show only mistaken ones.
class TrainingPackReviewScreen extends StatefulWidget {
  final TrainingPack pack;
  final Set<String> mistakenNames;

  const TrainingPackReviewScreen({
    super.key,
    required this.pack,
    this.mistakenNames = const {},
  });

  @override
  State<TrainingPackReviewScreen> createState() => _TrainingPackReviewScreenState();
}

class _TrainingPackReviewScreenState extends State<TrainingPackReviewScreen> {
  bool _onlyMistakes = false;
  final TextEditingController _searchController = TextEditingController();

  List<SavedHand> get _visibleHands {
    if (!_onlyMistakes) return widget.pack.hands;
    return [
      for (final h in widget.pack.hands)
        if (widget.mistakenNames.contains(h.name)) h
    ];
  }

  Future<void> _savePack() async {
    final service = context.read<TrainingPackStorageService>();
    await service.removePack(widget.pack);
    await service.addPack(widget.pack);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editHand(SavedHand hand) async {
    int rating = hand.rating;
    final Set<String> tags = {...hand.tags};
    final allTags = context.read<TagService>().tags;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(hand.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= 5; i++)
                        IconButton(
                          icon: Icon(
                            i <= rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setStateDialog(() => rating = i),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final tag in allTags)
                        FilterChip(
                          label: Text(tag),
                          selected: tags.contains(tag),
                          onSelected: (selected) => setStateDialog(() {
                            if (selected) {
                              tags.add(tag);
                            } else {
                              tags.remove(tag);
                            }
                          }),
                        ),
                    ],
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
                onPressed: () {
                  final updated = hand.copyWith(
                    rating: rating,
                    tags: tags.toList(),
                  );
                  final index = widget.pack.hands.indexOf(hand);
                  if (index != -1) {
                    widget.pack.hands[index] = updated;
                  }
                  _savePack();
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteHand(SavedHand hand) async {
    setState(() => widget.pack.hands.remove(hand));
    await _savePack();
  }

  Future<void> _confirmDeleteHand(SavedHand hand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hand?'),
        content:
            const Text('Are you sure you want to delete this hand?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _deleteHand(hand);
    }
  }

  Future<void> _showHandOptions(SavedHand hand) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(hand.name),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: const Text('Edit'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == 'edit') {
      await _editHand(hand);
    } else if (result == 'delete') {
      await _confirmDeleteHand(hand);
    }
  }

  String _generateMarkdown() {
    final buffer = StringBuffer('# ${widget.pack.name}\n\n');
    for (final hand in widget.pack.hands) {
      final mistake = widget.mistakenNames.contains(hand.name);
      final tags = hand.tags.join(', ');
      buffer.writeln('### ${hand.name}');
      buffer.writeln('- Rating: ${hand.rating}');
      if (tags.isNotEmpty) buffer.writeln('- Tags: $tags');
      buffer.writeln('- Mistake: ${mistake ? 'Yes' : 'No'}');
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  Future<void> _exportMarkdown() async {
    final markdown = _generateMarkdown();
    await Clipboard.setData(ClipboardData(text: markdown));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markdown copied to clipboard')),
      );
    }
  }

  Widget _buildHandTile(SavedHand hand) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(hand.name, style: const TextStyle(color: Colors.white)),
        subtitle: Wrap(
          spacing: 4,
          children: [for (final t in hand.tags) Chip(label: Text(t))],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 5; i++)
              Icon(
                i < hand.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
          ],
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) =>
                ReplaySpotWidget(spot: TrainingSpot.fromSavedHand(hand)),
          );
        },
        onLongPress: () => _showHandOptions(hand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleHands;
    final query = _searchController.text.toLowerCase();
    final hands = query.isEmpty
        ? visible
        : [
            for (final h in visible)
              if (h.name.toLowerCase().contains(query)) h
          ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Export to Markdown',
            onPressed: _exportMarkdown,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Show mistakes only'),
            value: _onlyMistakes,
            onChanged: widget.mistakenNames.isEmpty
                ? null
                : (v) => setState(() => _onlyMistakes = v),
            activeColor: Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search',
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: hands.isEmpty
                ? const Center(
                    child: Text(
                      'No spots',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: hands.length,
                    itemBuilder: (context, index) => _buildHandTile(hands[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

