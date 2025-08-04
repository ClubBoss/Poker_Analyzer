import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/learning_path_node_graph_snapshot_service.dart';
import '../../services/learning_graph_engine.dart';
import '../recent_auto_injections_screen.dart';

class DebugToolsSection extends StatefulWidget {
  const DebugToolsSection({super.key});

  @override
  State<DebugToolsSection> createState() => _DebugToolsSectionState();
}

class _DebugToolsSectionState extends State<DebugToolsSection> {
  bool _dumping = false;

  Future<void> _dumpGraph() async {
    if (_dumping || !kDebugMode) return;
    final engine = LearningPathEngine.instance.engine;
    if (engine == null) return;
    setState(() => _dumping = true);
    final text = LearningPathNodeGraphSnapshotService(
      engine: engine,
    ).debugSnapshot();
    if (!mounted) return;
    setState(() => _dumping = false);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Learning Path Graph'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (kDebugMode)
          ListTile(
            title: const Text('🧠 Dump Learning Path Graph'),
            onTap: _dumping ? null : _dumpGraph,
          ),
        ListTile(
          title: const Text('Recent Auto Theory Injections'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RecentAutoInjectionsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
