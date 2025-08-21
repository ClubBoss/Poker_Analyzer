import 'package:flutter/material.dart';
import '../models/v2/pack_ux_metadata.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_pack_search_service.dart';

/// Horizontal filter bar for training pack templates.
class TrainingPackSearchBarWidget extends StatefulWidget {
  const TrainingPackSearchBarWidget({super.key, required this.onFilterChanged});

  final ValueChanged<List<TrainingPackTemplateV2>> onFilterChanged;

  @override
  State<TrainingPackSearchBarWidget> createState() =>
      _TrainingPackSearchBarWidgetState();
}

class _TrainingPackSearchBarWidgetState
    extends State<TrainingPackSearchBarWidget> {
  TrainingPackLevel? _level;
  TrainingPackTopic? _topic;
  TrainingPackFormat? _format;

  List<TrainingPackTopic> _topics = TrainingPackTopic.values;

  @override
  void initState() {
    super.initState();
    _topics = TrainingPackSearchService.instance.getAvailableTopics();
    _update();
  }

  void _update() {
    final res = TrainingPackSearchService.instance.query(
      level: _level,
      topic: _topic,
      format: _format,
    );
    widget.onFilterChanged(res);
    setState(() {
      _topics = TrainingPackSearchService.instance.getAvailableTopics(
        level: _level,
      );
      if (_topic != null && !_topics.contains(_topic)) {
        _topic = null;
      }
    });
  }

  void _onLevelChanged(TrainingPackLevel? value) {
    setState(() => _level = value);
    _update();
  }

  void _onTopicChanged(TrainingPackTopic? value) {
    setState(() => _topic = value);
    _update();
  }

  void _onFormatPressed(int index) {
    setState(() {
      final selected =
          index == 0 ? TrainingPackFormat.cash : TrainingPackFormat.tournament;
      _format = _format == selected ? null : selected;
    });
    _update();
  }

  String _label(String name) => name[0].toUpperCase() + name.substring(1);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DropdownButton<TrainingPackLevel?>(
            value: _level,
            hint: const Text('Level'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              for (final l in TrainingPackLevel.values)
                DropdownMenuItem(value: l, child: Text(_label(l.name))),
            ],
            onChanged: _onLevelChanged,
          ),
          const SizedBox(width: 8),
          DropdownButton<TrainingPackTopic?>(
            value: _topic,
            hint: const Text('Topic'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              for (final t in _topics)
                DropdownMenuItem(value: t, child: Text(_label(t.name))),
            ],
            onChanged: _onTopicChanged,
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              _format == TrainingPackFormat.cash,
              _format == TrainingPackFormat.tournament,
            ],
            onPressed: _onFormatPressed,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Cash'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Tournament'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
