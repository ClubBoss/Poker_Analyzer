import 'package:flutter/material.dart';
import '../services/training_path_progress_service.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_session_service.dart';
import 'v2/training_pack_play_screen.dart';

class LearningPathOverviewScreen extends StatefulWidget {
  const LearningPathOverviewScreen({super.key});

  @override
  State<LearningPathOverviewScreen> createState() =>
      _LearningPathOverviewScreenState();
}

class _LearningPathOverviewScreenState
    extends State<LearningPathOverviewScreen> {
  late Future<Map<String, List<String>>> _stagesFuture;

  @override
  void initState() {
    super.initState();
    _stagesFuture = TrainingPathProgressService.instance.getStages();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<String>>>(
      future: _stagesFuture,
      builder: (context, snapshot) {
        final stages = snapshot.data ?? const <String, List<String>>{};
        return Scaffold(
          appBar: AppBar(
            title: const Text('Learning Path'),
          ),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    for (final entry in stages.entries)
                      _StageTile(stageId: entry.key, packIds: entry.value),
                  ],
                ),
        );
      },
    );
  }
}

class _StageTile extends StatefulWidget {
  final String stageId;
  final List<String> packIds;
  const _StageTile({required this.stageId, required this.packIds});

  @override
  State<_StageTile> createState() => _StageTileState();
}

class _StageTileState extends State<_StageTile> {
  double? _progress;
  Set<String>? _completed;
  bool _loaded = false;

  Future<void> _load() async {
    final svc = TrainingPathProgressService.instance;
    final progress = await svc.getProgressInStage(widget.stageId);
    final completed = await svc.getCompletedPacksInStage(widget.stageId);
    if (mounted) {
      setState(() {
        _progress = progress;
        _completed = completed.toSet();
        _loaded = true;
      });
    }
  }

  String _title() {
    if (widget.stageId.isEmpty) return widget.stageId;
    return widget.stageId[0].toUpperCase() + widget.stageId.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress ?? 0.0;
    return ExpansionTile(
      title: Row(
        children: [
          Expanded(child: Text(_title())),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(value: progress),
          ),
        ],
      ),
      onExpansionChanged: (expanded) {
        if (expanded && !_loaded) {
          _load();
        }
      },
      children: [
        if (!_loaded)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          for (final id in widget.packIds)
            _PackTile(
              packId: id,
              completed: _completed?.contains(id) ?? false,
            ),
      ],
    );
  }
}

class _PackTile extends StatelessWidget {
  final String packId;
  final bool completed;
  const _PackTile({required this.packId, required this.completed});

  @override
  Widget build(BuildContext context) {
    final tpl = TrainingPackTemplateService.getById(packId, context);
    final title = tpl?.name ?? packId;
    return ListTile(
      title: Text(
        title,
        style: completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      trailing: completed ? const Text('✅') : null,
      onTap: completed
          ? null
          : () async {
              if (tpl == null) return;
              await TrainingSessionService().startFromTemplate(tpl);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingPackPlayScreen(
                      template: tpl,
                      original: tpl,
                    ),
                  ),
                );
              }
            },
    );
  }
}
