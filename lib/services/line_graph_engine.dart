import 'dart:math';

import '../models/line_graph_request.dart';
import '../models/action_line.dart';

class LineGraphEngine {
  LineGraphEngine({Map<String, List<_ActionTemplate>>? templates, int? seed})
      : _templatesByTag = templates ?? _defaultTemplates,
        _rand = Random(seed);

  final Map<String, List<_ActionTemplate>> _templatesByTag;
  final Random _rand;

  static const List<String> _stageOrder = ['preflop', 'flop', 'turn', 'river'];

  List<ActionLine> generate(LineGraphRequest request, {int count = 1}) {
    final stages = _stagesUpTo(request.gameStage);
    final lines = <ActionLine>[];
    var attempts = 0;
    while (lines.length < count && attempts < count * 10) {
      attempts++;
      final actions = <String>[];
      final tags = <String>{};
      for (final stage in stages) {
        final template = _pickTemplate(stage, request.requiredTags);
        if (template == null) continue;
        actions.addAll(template.actions);
        tags.addAll(template.tags);
      }
      if (actions.length < request.minActions ||
          actions.length > request.maxActions) {
        continue;
      }
      if (request.requiredTags.every(tags.contains)) {
        lines.add(
          ActionLine(actions: actions, street: request.gameStage, tags: tags),
        );
      }
    }
    return lines;
  }

  _ActionTemplate? _pickTemplate(String street, List<String> requiredTags) {
    final candidates = <_ActionTemplate>[];
    if (requiredTags.isNotEmpty) {
      for (final tag in requiredTags) {
        final list = _templatesByTag[tag];
        if (list != null) {
          candidates.addAll(list.where((t) => t.street == street));
        }
      }
    }
    candidates.addAll(
      _templatesByTag['default']?.where((t) => t.street == street) ?? const [],
    );
    if (candidates.isEmpty) return null;
    final totalWeight = candidates.fold<int>(0, (s, t) => s + t.weight);
    var roll = _rand.nextInt(totalWeight);
    for (final t in candidates) {
      roll -= t.weight;
      if (roll < 0) return t;
    }
    return candidates.first;
  }

  static List<String> _stagesUpTo(String stage) {
    final idx = _stageOrder.indexOf(stage);
    if (idx == -1) return const [];
    return _stageOrder.sublist(0, idx + 1);
  }

  static final Map<String, List<_ActionTemplate>> _defaultTemplates = {
    'default': [
      _ActionTemplate(
        street: 'preflop',
        actions: ['open', 'call'],
        tags: {'preflop'},
      ),
      _ActionTemplate(
        street: 'flop',
        actions: ['cbet', 'call'],
        tags: {'cbet'},
      ),
      _ActionTemplate(
        street: 'turn',
        actions: ['check', 'bet'],
        tags: {'probe'},
      ),
      _ActionTemplate(
        street: 'river',
        actions: ['check', 'call'],
        tags: {'showdown'},
      ),
    ],
    'probe': [
      _ActionTemplate(
        street: 'turn',
        actions: ['check', 'probe'],
        tags: {'probe'},
        weight: 2,
      ),
    ],
    'delayedCbet': [
      _ActionTemplate(
        street: 'turn',
        actions: ['check', 'check', 'delayedCbet'],
        tags: {'delayedCbet'},
        weight: 2,
      ),
    ],
  };
}

class _ActionTemplate {
  final String street;
  final List<String> actions;
  final Set<String> tags;
  final int weight;

  const _ActionTemplate({
    required this.street,
    required this.actions,
    this.tags = const {},
    this.weight = 1,
  });
}
