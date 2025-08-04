import 'package:flutter/material.dart';

import '../models/recall_failure_spotting.dart';
import '../services/recall_failure_log_service.dart';

/// Displays a list of recall failure spottings for a given hotspot.
class RecallHotspotExamplesScreen extends StatefulWidget {
  static const route = '/recallHotspotExamples';
  const RecallHotspotExamplesScreen({super.key});

  @override
  State<RecallHotspotExamplesScreen> createState() =>
      _RecallHotspotExamplesScreenState();
}

class _RecallHotspotExamplesScreenState
    extends State<RecallHotspotExamplesScreen> {
  late Future<List<RecallFailureSpotting>> _future;
  late String _mode;
  late String _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _mode = args['mode'] as String? ?? 'tag';
      _id = args['id'] as String? ?? '';
    } else {
      _mode = 'tag';
      _id = '';
    }
    _future = RecallFailureLogService.instance
        .getSpottingsForHotspot(_mode, _id);
  }

  void _openAnalyzer(String spotId) {
    Navigator.of(context)
        .pushNamed('/analyzer', arguments: {'spotId': spotId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotspot Examples')),
      body: FutureBuilder<List<RecallFailureSpotting>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('No spottings found'));
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final s = data[index];
              return ListTile(
                title: Text(s.spotId),
                subtitle:
                    Text('${_formatDate(s.timestamp)} • ${s.decayStage}'),
                trailing: TextButton(
                  onPressed: () => _openAnalyzer(s.spotId),
                  child: const Text('Open in Analyzer'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
