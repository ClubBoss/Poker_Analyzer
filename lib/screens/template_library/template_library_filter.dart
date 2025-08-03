part of '../template_library_screen.dart';

extension TemplateLibraryFilter on _TemplateLibraryScreenState {
  List<v2.TrainingPackTemplate> _applyAudienceFilter(
      List<v2.TrainingPackTemplate> list) {
    if (_audienceFilter == 'all') return list;
    return [
      for (final t in list)
        if (t.audience == _audienceFilter) t
    ];
  }

  List<v2.TrainingPackTemplate> _applyTrainingTypeFilter(
      List<v2.TrainingPackTemplate> list) {
    if (_trainingType == null) return list;
    return TrainingTypeFilterService.filterByType(
        list.toList(), {_trainingType!});
  }

  bool _matchesTagsAndCategories(TrainingPackTemplate t) {
    final tags = {..._selectedTags, ..._activeTags};
    final cats = {..._selectedCategories, ..._activeCategories};
    if (tags.isEmpty && cats.isEmpty) return true;
    final tagOk = tags.isEmpty || t.tags.any(tags.contains);
    var catOk = cats.isEmpty;
    if (!catOk) {
      if (t.category != null && cats.contains(t.category)) {
        catOk = true;
      } else {
        for (final h in t.hands) {
          final c = h.category;
          if (c != null && cats.contains(c)) {
            catOk = true;
            break;
          }
        }
      }
    }
    return tagOk && catOk;
  }

  List<TrainingPackTemplate> _applyFilters(
      List<TrainingPackTemplate> templates) {
    var visible = templates;
    if (_filter == 'tournament') {
      visible = [
        for (final t in visible)
          if (t.gameType.toLowerCase().startsWith('tour')) t
      ];
    } else if (_filter == 'cash') {
      visible = [
        for (final t in visible)
          if (t.gameType.toLowerCase().contains('cash')) t
      ];
    } else if (_filter == 'mistakes') {
      final service = context.read<MistakeReviewPackService>();
      visible = [
        for (final t in visible)
          if (service.hasMistakes(t.id)) t
      ];
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (t.name.toLowerCase().contains(query) ||
              t.tags.any((tag) => tag.toLowerCase().contains(query)))
            t
      ];
    }
    if (_needsPractice) {
      visible = [
        for (final t in visible)
          if (_needsPracticeIds.contains(t.id)) t
      ];
    }
    if (_needsRepetition) {
      visible = [
        for (final t in visible)
          if (_needsRepetitionIds.contains(t.id)) t
      ];
    }
    if (_needsPracticeOnly) {
      visible = [
        for (final t in visible)
          if (_needsPracticeOnlyIds.contains(t.id)) t
      ];
    }
    if (_favoritesOnly) {
      visible = [
        for (final t in visible)
          if (_favorites.contains(t.id)) t
      ];
    }
    if (_inProgressOnly) {
      visible = [
        for (final t in visible)
          if (_progressPercentFor(t) > 0 && _progressPercentFor(t) < 100) t
      ];
    }
    if (_masteredOnly) {
      visible = [
        for (final t in visible)
          if (_mastered.contains(t.id)) t
      ];
    }
    if (_completedOnly) {
      visible = [
        for (final t in visible)
          if (_isFullyCompleted(t)) t
      ];
    }
    if (_hideCompleted && !_favoritesOnly && !_completedOnly) {
      visible = [
        for (final t in visible)
          if (!_isCompleted(t.id) ||
              _favorites.contains(t.id) ||
              _recent.any((e) => e.id == t.id))
            t
      ];
    }
    if (_selectedTags.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _activeTags.isNotEmpty ||
        _activeCategories.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (_matchesTagsAndCategories(t)) t
      ];
    }
    if (_popularOnly) {
      visible = [
        for (final t in visible)
          if (_popularIds.contains(t.id)) t
      ];
    }
    if (_recommendedOnly) {
      final rec = context.read<RecommendedPackService>();
      visible = [
        for (final t in visible)
          if (t.tags.any(rec.preferredTags.contains) ||
              t.hands.any((h) =>
                  h.category != null &&
                  rec.preferredCategories.contains(h.category)))
            t
      ];
    }
    if (_difficultyFilters.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (_difficultyFilters.contains((t as dynamic).difficultyLevel)) t
      ];
    }
    if (_streetFilters.isNotEmpty) {
      visible = [
        for (final t in visible)
          if ((t as dynamic).targetStreet != null &&
              _streetFilters.contains((t as dynamic).targetStreet))
            t
      ];
    }
    if (_availableOnly) {
      visible = [
        for (final t in visible)
          if (_packUnlocked[t.id] != false) t
      ];
    }
    if (_weakOnly) {
      visible = [
        for (final t in visible)
          if (_weakTagMap.containsKey(t.id)) t
      ];
    }
    return visible;
  }
}
