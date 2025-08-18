import 'package:flutter/material.dart';
import '../services/completed_training_pack_registry.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../helpers/date_utils.dart';
import '../services/training_session_launcher.dart';

class TrainingPackHistoryListWidget extends StatefulWidget {
  const TrainingPackHistoryListWidget({
    super.key,
    this.registry,
    this.launcher = const TrainingSessionLauncher(),
  });

  final CompletedTrainingPackRegistry? registry;
  final TrainingSessionLauncher launcher;

  @override
  State<TrainingPackHistoryListWidget> createState() =>
      _TrainingPackHistoryListWidgetState();
}

class _TrainingPackHistoryListWidgetState
    extends State<TrainingPackHistoryListWidget> {
  late final CompletedTrainingPackRegistry _registry;
  var _items = <_HistoryItem>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry ?? CompletedTrainingPackRegistry();
    _load();
  }

  Future<void> _load() async {
    final fingerprints = await _registry.listCompletedFingerprints();
    final list = <_HistoryItem>[];
    for (final fp in fingerprints) {
      final data = await _registry.getCompletedPackData(fp);
      if (data == null) continue;
      final yaml = data['yaml'];
      if (yaml is! String) continue;
      String name = 'Unknown Pack';
      try {
        name = TrainingPackTemplateV2.fromYamlString(yaml).name;
      } catch (_) {}
      final tsStr = data['timestamp'];
      DateTime? timestamp;
      if (tsStr is String) {
        try {
          timestamp = DateTime.parse(tsStr);
        } catch (_) {}
      }
      if (timestamp == null) continue;
      final acc = (data['accuracy'] as num?)?.toDouble();
      final durationMs = (data['durationMs'] as num?)?.toInt();
      list.add(
        _HistoryItem(
          fingerprint: fp,
          name: name,
          timestamp: timestamp,
          accuracy: acc,
          duration: durationMs != null
              ? Duration(milliseconds: durationMs)
              : null,
        ),
      );
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  String _buildSubtitle(_HistoryItem item) {
    var subtitle = 'Completed on ${formatDateTime(item.timestamp)}';
    if (item.accuracy != null) {
      final pct = (item.accuracy! * 100).toStringAsFixed(0);
      subtitle += ', Accuracy: $pct%';
    }
    if (item.duration != null) {
      subtitle += ', Duration: ${formatDuration(item.duration!)}';
    }
    return subtitle;
  }

  Future<void> _replay(_HistoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat this training pack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replay'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final data = await _registry.getCompletedPackData(item.fingerprint);
    final yaml = data?['yaml'];
    if (yaml is! String) return;
    await widget.launcher.launchFromYaml(yaml);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No completed packs yet'));
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(_buildSubtitle(item)),
          onTap: () => _replay(item),
        );
      },
    );
  }
}

class _HistoryItem {
  final String fingerprint;
  final String name;
  final DateTime timestamp;
  final double? accuracy;
  final Duration? duration;
  _HistoryItem({
    required this.fingerprint,
    required this.name,
    required this.timestamp,
    this.accuracy,
    this.duration,
  });
}
