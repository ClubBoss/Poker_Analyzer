import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/completed_training_pack_registry.dart';
import '../services/training_session_launcher.dart';

class CompletedSessionDetailScreen extends StatefulWidget {
  final String fingerprint;
  const CompletedSessionDetailScreen({super.key, required this.fingerprint});

  @override
  State<CompletedSessionDetailScreen> createState() =>
      _CompletedSessionDetailScreenState();
}

class _CompletedSessionDetailScreenState
    extends State<CompletedSessionDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final registry = CompletedTrainingPackRegistry();
    final data = await registry.getCompletedPackData(widget.fingerprint);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text('Session not found'))
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final yaml = _data!['yaml'] as String?;
    final timestampStr = _data!['timestamp'] as String?;
    final type = _data!['type'] as String?;
    final accuracy = (_data!['accuracy'] as num?)?.toDouble();

    String name = 'Unknown Pack';
    TrainingPackTemplateV2? pack;
    if (yaml != null) {
      try {
        pack = TrainingPackTemplateV2.fromYamlString(yaml);
        name = pack.name;
      } catch (_) {}
    }

    TrainingType? typeEnum;
    if (type != null) {
      try {
        typeEnum = TrainingType.values.firstWhere((t) => t.name == type);
      } catch (_) {}
    }
    final typeLabel = typeEnum?.label ?? type ?? 'Unknown';

    DateTime? ts;
    if (timestampStr != null) {
      try {
        ts = DateTime.parse(timestampStr);
      } catch (_) {}
    }
    final dateStr = ts != null
        ? DateFormat.yMMMd(Intl.getCurrentLocale()).add_Hm().format(ts)
        : 'Unknown';

    final accuracyStr = accuracy != null
        ? '${(accuracy * 100).toStringAsFixed(0)}%'
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Training Type: $typeLabel'),
          Text('Accuracy: $accuracyStr'),
          Text('Completed: $dateStr'),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                yaml ?? '',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              if (yaml != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Export'),
                  onPressed: () => Share.share(yaml),
                ),
              if (pack != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry'),
                  onPressed: () =>
                      const TrainingSessionLauncher().launch(pack!),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete Session?'),
                        content: const Text(
                          'Are you sure you want to delete this session?',
                        ),
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
                      );
                    },
                  );
                  if (confirm == true) {
                    await CompletedTrainingPackRegistry().deleteCompletedPack(
                      widget.fingerprint,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
