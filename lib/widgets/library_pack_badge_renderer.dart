import 'package:flutter/material.dart';

import '../services/pack_library_completion_service.dart';

/// Renders a small badge for a library pack based on completion stats.
class LibraryPackBadgeRenderer extends StatefulWidget {
  final String packId;
  const LibraryPackBadgeRenderer({super.key, required this.packId});

  @override
  State<LibraryPackBadgeRenderer> createState() =>
      _LibraryPackBadgeRendererState();
}

class _LibraryPackBadgeRendererState extends State<LibraryPackBadgeRenderer> {
  static final _cache = <String, PackCompletionData?>{};
  late Future<PackCompletionData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PackCompletionData?> _load() async {
    if (_cache.containsKey(widget.packId)) {
      return _cache[widget.packId];
    }
    final data = await PackLibraryCompletionService.instance.getCompletion(
      widget.packId,
    );
    _cache[widget.packId] = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackCompletionData?>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.total <= 0) {
          return const SizedBox.shrink();
        }
        final accuracy = data.accuracy;
        if (accuracy <= 0) return const SizedBox.shrink();
        String label;
        if (accuracy >= 1.0) {
          label = '🌟 Perfect';
        } else if (accuracy >= 0.8) {
          label = '✅ Completed';
        } else {
          label = '🕓 In Progress';
        }
        final color = Theme.of(context).colorScheme.secondary;
        final pct = (accuracy * 100).round();
        final badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label $pct%',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
        return Tooltip(message: label, child: badge);
      },
    );
  }
}
