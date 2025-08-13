part of 'training_pack_template_list_screen.dart';

mixin TrainingPackTemplateFilterPanel on State<TrainingPackTemplateListScreen> {
  void _showFilters() {
    final tags = <String>{for (final t in _templates) ...t.tags};
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (_) => setState(() => _selectedType = null),
              ),
              ChoiceChip(
                label: const Text('Tournament'),
                selected: _selectedType == GameType.tournament,
                onSelected: (_) =>
                    setState(() => _selectedType = GameType.tournament),
              ),
              ChoiceChip(
                label: const Text('Cash'),
                selected: _selectedType == GameType.cash,
                onSelected: (_) =>
                    setState(() => _selectedType = GameType.cash),
              ),
              ChoiceChip(
                label: const Text('🏆 Completed'),
                selected: _completedOnly,
                onSelected: (_) =>
                    setState(() => _completedOnly = !_completedOnly),
              ),
              ChoiceChip(
                label: const Text('🟡 В процессе'),
                selected: _showInProgressOnly,
                onSelected: (_) => _setShowInProgressOnly(!_showInProgressOnly),
              ),
              ChoiceChip(
                label: const Text('ICM Only'),
                selected: _icmOnly,
                onSelected: (_) => setState(() => _icmOnly = !_icmOnly),
              ),
              for (final d in ['Beginner', 'Intermediate', 'Advanced'])
                ChoiceChip(
                  label: Text(d),
                  selected: _difficultyFilter == d,
                  onSelected: (_) =>
                      _setDifficultyFilter(_difficultyFilter == d ? null : d),
                ),
              DropdownButton<String>(
                value: _streetFilter ?? 'any',
                dropdownColor: Colors.grey[900],
                hint: const Text('All Streets'),
                onChanged: (v) => _setStreetFilter(v == 'any' ? null : v),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('All Streets')),
                  DropdownMenuItem(value: 'preflop', child: Text('Preflop')),
                  DropdownMenuItem(value: 'flop', child: Text('Flop')),
                  DropdownMenuItem(value: 'turn', child: Text('Turn')),
                  DropdownMenuItem(value: 'river', child: Text('River')),
                ],
              ),
              DropdownButton<String>(
                value: _stackFilter ?? 'any',
                dropdownColor: Colors.grey[900],
                hint: const Text('Any Stack'),
                onChanged: (v) => _setStackFilter(v == 'any' ? null : v),
                items: [
                  const DropdownMenuItem(
                      value: 'any', child: Text('Any Stack')),
                  for (final r in _stackRanges)
                    DropdownMenuItem(value: r, child: Text('${r}bb')),
                ],
              ),
              DropdownButton<HeroPosition?>(
                value: _posFilter,
                dropdownColor: Colors.grey[900],
                hint: const Text('Any Pos'),
                onChanged: (v) => _setPosFilter(v),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any Pos')),
                  for (final p in HeroPosition.values)
                    DropdownMenuItem(value: p, child: Text(p.label)),
                ],
              ),
              if (tags.isNotEmpty) ...[
                ChoiceChip(
                  label: const Text('All Tags'),
                  selected: _selectedTag == null,
                  onSelected: (_) => setState(() => _selectedTag = null),
                ),
                for (final tag in tags)
                  ChoiceChip(
                    label: Text(tag),
                    selected: _selectedTag == tag,
                    onSelected: (_) => setState(() => _selectedTag = tag),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTemplateStats(TrainingPackTemplate t, int total) {
    final items = <Widget>[];
    final pos = t.posRangeLabel();
    if (pos.isNotEmpty) {
      items.add(Text(pos,
          style: const TextStyle(fontSize: 12, color: Colors.white70)));
      items.add(const SizedBox(height: 4));
    }
    final progVal =
        total > 0 ? (_progress[t.id]?.clamp(0, total) ?? 0) / total : 0.0;
    final progColor = t.goalAchieved ? Colors.green : Colors.orange;
    items.add(LinearProgressIndicator(
      value: progVal,
      color: progColor,
      backgroundColor: progColor.withValues(alpha: 0.3),
    ));
    items.add(const SizedBox(height: 4));
    if (t.targetStreet != null && t.streetGoal > 0) {
      final val =
          (_streetProgress[t.id]?.clamp(0, t.streetGoal) ?? 0) / t.streetGoal;
      items.add(Row(
        children: [
          Expanded(child: LinearProgressIndicator(value: val)),
          const SizedBox(width: 8),
          Text('${(val * 100).round()}%', style: const TextStyle(fontSize: 12)),
        ],
      ));
      items.add(const SizedBox(height: 4));
    }
    if (t.focusHandTypes.isNotEmpty) {
      final totals = _handGoalTotal[t.id] ?? {};
      final progress = _handGoalProgress[t.id] ?? {};
      for (final g in t.focusHandTypes) {
        final total = totals[g.label] ?? 0;
        if (total > 0) {
          final done = progress[g.label]?.clamp(0, total) ?? 0;
          final val = done / total;
          items.add(Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: val,
                  color: Colors.purpleAccent,
                  backgroundColor: Colors.purpleAccent.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text('${g.label} ${(val * 100).round()}%',
                  style: const TextStyle(fontSize: 12)),
            ],
          ));
          items.add(const SizedBox(height: 4));
        }
      }
    }
    final ratio = t.goalTarget > 0
        ? (t.goalProgress / t.goalTarget).clamp(0.0, 1.0)
        : 0.0;
    if (t.goalTarget > 0) {
      items.add(Row(
        children: [
          Expanded(child: LinearProgressIndicator(value: ratio)),
          const SizedBox(width: 8),
          Text('${(ratio * 100).round()}%',
              style: const TextStyle(fontSize: 12)),
        ],
      ));
    }
    final prog = _progress[t.id];
    if (prog != null) {
      items.add(Text(
        '${prog.clamp(0, total)}/$total done',
        style: const TextStyle(fontSize: 12, color: Colors.white54),
      ));
    }
    if (t.description.trim().isNotEmpty) {
      items.add(Text(
        t.description.split('\n').first,
        style: const TextStyle(fontSize: 12),
      ));
    }
    final tags = _topTags(t);
    if (tags.isNotEmpty) {
      items.add(Text(
        'Tags: ${tags.join(', ')}',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ));
    }
    if (t.focusTags.isNotEmpty) {
      items.add(Text(
        '🎯 Focus: ${t.focusTags.join(', ')}',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ));
    }
    if (t.focusHandTypes.isNotEmpty) {
      items.add(Text(
        '🃏 Hand Goal: ${t.focusHandTypes.join(', ')}',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ));
    }
    final stat = _stats[t.id];
    if (stat != null) {
      items.add(Text(
        'Accuracy ${(stat.accuracy * 100).toStringAsFixed(0)}% • EV ${stat.evSum.toStringAsFixed(1)} • ICM ${stat.icmSum.toStringAsFixed(1)}',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ));
    }
    if (t.lastGeneratedAt != null) {
      items.add(Text(
        'Last generated: ${timeago.format(t.lastGeneratedAt!)}',
        style: const TextStyle(fontSize: 12, color: Colors.white54),
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) return items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}
