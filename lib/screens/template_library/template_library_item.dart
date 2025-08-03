part of '../template_library_screen.dart';

extension TemplateLibraryItem on _TemplateLibraryScreenState {
  Widget _item(TrainingPackTemplate t, [String? note]) {
    final l = AppLocalizations.of(context)!;
    final parts = t.version.split('.');
    final version = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : t.version;
    final tags = t.tags.take(3).toList();
    final weakTag = _weakTagMap[t.id];
    final combinedNote = weakTag != null
        ? (note != null
            ? '$note • Weak skill: $weakTag'
            : 'Weak skill: $weakTag')
        : note;
    final isNew =
        t.isBuiltIn && DateTime.now().difference(t.createdAt).inDays < 7;
    Widget progress() {
      final stat = _stats[t.id];
      if (stat == null) return const SizedBox.shrink();
      final ev = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
      final icm = stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct;
      if (ev == 0 || icm == 0) return const SizedBox.shrink();
      final val = ((stat.accuracy * 100) + ev + icm) / 3;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Semantics(
          label: l.percentLabel(val.round()),
          child: LinearProgressIndicator(
            value: val / 100,
            backgroundColor: Colors.white12,
            color: _progressColor(val),
            minHeight: 3,
          ),
        ),
      );
    }

    Widget handsProgress() {
      final c = _handsCompleted[t.id];
      if (c == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '$c / ${t.spots.length}',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      );
    }

    final tagsWidget = tags.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final tag in tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final locked = _packUnlocked[t.id] == false;
    final reason = _lockReasons[t.id];
    final previewRequired =
        t.spots.length > 30 && !_previewCompleted.contains(t.id);

    if (_compactMode) {
      Widget card = Card(
        child: ListTile(
          dense: true,
          trailing: _progressPercentFor(t) == 100
              ? const Tooltip(
                  message: 'Пройден на 100%',
                  child: Icon(Icons.star, size: 16, color: Colors.amber),
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (combinedNote != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    combinedNote,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.name,
                      style: t.isBuiltIn
                          ? TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            )
                          : null,
                    ),
                  ),
                  if (t.targetStreet != null)
                    _streetBadge(t.targetStreet!, compact: true),
                  trainingTypeBadge(t.trainingType.name, compact: true),
                ],
              ),
              if (locked && reason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(reason,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              if (t.category != null && t.category!.isNotEmpty)
                Text(
                  translateCategory(t.category),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              handsProgress(),
              progress(),
              if (tags.isNotEmpty) tagsWidget,
            ],
          ),
          onTap: () async {
            if (await _maybeAutoSample(TrainingPackTemplateV2.fromTemplate(
              t,
              type: const TrainingTypeEngine().detectTrainingType(t),
            ))) {
              return;
            }
            final create = await showDialog<bool>(
              context: context,
              builder: (_) => TemplatePreviewDialog(template: t),
            );
            if (create == true && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreatePackFromTemplateScreen(template: t)),
              );
            }
          },
        ),
      );
      card = Stack(
        children: [
          card,
          if (weakTag != null)
          Positioned(
            top: 4,
            left: 4,
            child: Tooltip(
              message: 'Weak skill: $weakTag',
              child: const Icon(
                Icons.brightness_1,
                size: 10,
                color: Colors.redAccent,
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: PackProgressOverlay(templateId: t.id, size: 20),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: LibraryPackBadgeRenderer(packId: t.id),
        ),
        if (locked && reason != null)
          Positioned(
            bottom: 4,
            left: 4,
            child: PackUnlockRequirementBadge(
              text: reason,
              tooltip: reason,
            ),
          ),
      ],
    );
      if (_isStarter(t)) {
        card = Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: card,
        );
      }
      Widget widget = GestureDetector(
        onLongPress: () => _showPackSheet(context, t),
        child: card,
      );
      if (locked) {
        widget = Stack(
          children: [
            Opacity(opacity: 0.5, child: widget),
            Positioned.fill(
              child: Tooltip(
                message: reason == null
                    ? 'Пак заблокирован'
                    : 'Чтобы разблокировать: $reason',
                child: InkWell(
                  onTap: () => _onLockedPackTap(t, reason),
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child:
                        const Icon(Icons.lock, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return Container(
        key: _itemKeys.putIfAbsent(t.id, () => GlobalKey()),
        child: widget,
      );
    }

    Widget card = Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorFromHex(t.defaultColor)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (combinedNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  combinedNote,
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            if (_isStarter(t))
              Row(
                children: [
                  const Icon(Icons.rocket_launch,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(l.starterBadge,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueAccent)),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                if (t.isBuiltIn) ...[
                  const Icon(Icons.shield, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                if (_recent.any((e) => e.id == t.id)) ...[
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                if (_needsRepetitionIds.contains(t.id)) ...[
                  const Text('⏳', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                ],
                if (_needsPracticeOnlyIds.contains(t.id)) ...[
                  const Text('📉', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    t.name,
                    style: t.isBuiltIn
                        ? TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          )
                        : null,
                  ),
                ),
                if (t.targetStreet != null)
                  _streetBadge(t.targetStreet!, compact: false),
                trainingTypeBadge(t.trainingType.name, compact: false),
                if (t.category != null && t.category!.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    translateCategory(t.category),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (_mastered.contains(t.id)) ...[
                  const SizedBox(width: 4),
                  Text(
                    l.masteredBadge,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
                if (_progressPercentFor(t) == 100) ...[
                  const SizedBox(width: 4),
                  const Tooltip(
                    message: 'Пройден на 100%',
                    child: Icon(Icons.star, size: 16, color: Colors.amber),
                  ),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: isNew
                      ? Padding(
                          key: const ValueKey('new'),
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(l.newBadge,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        )
                      : const SizedBox.shrink(key: ValueKey('notNew')),
                ),
              ],
            ),
            handsProgress(),
            progress(),
            if (tags.isNotEmpty) tagsWidget,
          ],
        ),
        subtitle: () {
          final main = '${t.hands.length} ${l.hands} • v$version';
          final stat = _stats[t.id];
          if (stat == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(main),
                const SizedBox(height: 24),
              ],
            );
          }
          final date =
              DateFormat('dd MMM', Intl.getCurrentLocale()).format(stat.last);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(main),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l.accuracySemantics((stat.accuracy * 100).round()),
                      child: LinearProgressIndicator(
                        value: stat.accuracy.clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        color: _colorFor(stat.accuracy),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.percentLabel((stat.accuracy * 100).round()),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${l.lastTrained}: $date',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          );
        }(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _togglePinned(t.id),
              icon: Text('📌',
                  style: TextStyle(
                      fontSize: 20,
                      color: _pinned.contains(t.id)
                          ? Colors.orange
                          : Colors.white54)),
            ),
            IconButton(
              icon: Icon(
                _favorites.contains(t.id) ? Icons.star : Icons.star_border,
              ),
              color: _favorites.contains(t.id) ? Colors.amber : Colors.white54,
              onPressed: () => _toggleFavorite(t.id),
            ),
            TextButton(
              onPressed: locked || previewRequired
                  ? null
                  : () async {
                      final tplV2 = TrainingPackTemplateV2.fromTemplate(
                        t,
                        type:
                            const TrainingTypeEngine().detectTrainingType(t),
                      );
                      await const TrainingSessionLauncher().launch(tplV2);
                    },
              child: const Text('▶️ Train'),
            ),
            if (previewRequired) const SamplePackPreviewTooltip(),
            SamplePackPreviewButton(template: t, locked: locked),
          ],
        ),
        onTap: () async {
          if (await _maybeAutoSample(t)) return;
          final create = await showDialog<bool>(
            context: context,
            builder: (_) => TemplatePreviewDialog(template: t),
          );
          if (create == true && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreatePackFromTemplateScreen(template: t)),
            );
          }
        },
      ),
    );
    card = Stack(
      children: [
        card,
        if (weakTag != null)
          Positioned(
            top: 4,
            left: 4,
            child: Tooltip(
              message: 'Weak skill: $weakTag',
              child: const Icon(
                Icons.brightness_1,
                size: 10,
                color: Colors.redAccent,
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: PackProgressOverlay(templateId: t.id, size: 20),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: LibraryPackBadgeRenderer(packId: t.id),
        ),
        if (locked && reason != null)
          Positioned(
            bottom: 4,
            left: 4,
            child: PackUnlockRequirementBadge(
              text: reason,
              tooltip: reason,
            ),
          ),
      ],
    );
    if (_isStarter(t)) {
      card = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: card,
      );
    }
    Widget widget = GestureDetector(
      onLongPress: () => _showPackSheet(context, t),
      child: card,
    );
    if (locked) {
      widget = Stack(
        children: [
          Opacity(opacity: 0.5, child: widget),
          Positioned.fill(
            child: Tooltip(
              message: reason == null
                  ? 'Пак заблокирован'
                  : 'Чтобы разблокировать: $reason',
              child: InkWell(
                onTap: reason != null ? () => _showUnlockHint(reason) : null,
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const Icon(Icons.lock, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      key: _itemKeys.putIfAbsent(t.id, () => GlobalKey()),
      child: widget,
    );
  }

}
