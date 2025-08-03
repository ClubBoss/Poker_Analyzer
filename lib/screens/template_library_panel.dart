part of 'template_library_core.dart';

// Toolbar and filtering utilities.

extension TemplateLibraryToolbar on _TemplateLibraryScreenState {
  AppBar _buildAppBar(AppLocalizations l) {
    return AppBar(
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Поиск', border: InputBorder.none),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _filter,
            underline: const SizedBox.shrink(),
            onChanged: (v) => v != null ? _setFilter(v) : null,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All')),
              const DropdownMenuItem(
                  value: 'tournament', child: Text('Tournament')),
              const DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(
                  value: 'mistakes', child: Text(l.filterMistakes)),
            ],
          ),
          const SizedBox(width: 8),
          DropdownButton<TrainingType?>(
            value: _trainingType,
            hint: const Text('Type'),
            underline: const SizedBox.shrink(),
            onChanged: _setTrainingType,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...[
                for (final t in TrainingType.values)
                  DropdownMenuItem(value: t, child: Text(t.label))
              ]
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Street',
            onSelected: _toggleStreet,
            itemBuilder: (ctx) => [
              for (final street in ['preflop', 'flop', 'turn', 'river'])
                CheckedPopupMenuItem(
                  value: street,
                  checked: _streetFilters.contains(street),
                  child: Text(getStreetLabel(street)),
                ),
            ],
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.white70),
                for (final s in _streetFilters)
                  _streetBadge(s, compact: true),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(_sortIcons[_sort], color: Colors.white70),
            onSelected: _setSort,
            initialValue: _sort,
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: kSortEdited,
                child: Text(AppLocalizations.of(ctx)!.sortNewest),
              ),
              PopupMenuItem(
                value: kSortSpots,
                child: Text(AppLocalizations.of(ctx)!.sortMostHands),
              ),
              PopupMenuItem(
                value: kSortName,
                child: Text(AppLocalizations.of(ctx)!.sortName),
              ),
              PopupMenuItem(
                value: kSortProgress,
                child: Text(AppLocalizations.of(ctx)!.sortProgress),
              ),
              PopupMenuItem(
                value: kSortCoverage,
                child: Text(AppLocalizations.of(ctx)!.sortCoverage),
              ),
              const PopupMenuItem(
                value: kSortCombinedTrending,
                child: Text('🔥 Популярное'),
              ),
              const PopupMenuItem(
                value: kSortInProgress,
                child: Text('In Progress'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white70),
            onSelected: _setLibrarySort,
            initialValue: _librarySort,
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: kLibSortProgress,
                child: Text('By Progress'),
              ),
              PopupMenuItem(
                value: kLibSortAccuracy,
                child: Text('By Accuracy'),
              ),
              PopupMenuItem(
                value: kLibSortLastTrained,
                child: Text('Last Trained'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
            );
          },
        ),
        IconButton(
          icon: const Text('📊', style: TextStyle(fontSize: 20)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrainingStatsScreen()),
            );
          },
        ),
        SyncStatusIcon.of(context),
      ],
    );
  }
}
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

extension TemplateLibraryPanel on _TemplateLibraryScreenState {
  Widget _recommendedCategoryCard() {
    return FutureBuilder<String?>(
      future: context
          .read<WeakSpotRecommendationService>()
          .getRecommendedCategory(),
      builder: (context, snap) {
        final cat = snap.data;
        if (cat == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text(
                      '📂 Рекомендуемая категория',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  translateCategory(cat),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Подтяните навык в этой области',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _setActiveCategory(cat),
                    child: const Text('Начать'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Banner prompting the user to train the weakest statistical category.
  Widget _weakCategoryBanner() {
    final cat = _weakCategory;
    final pack = _weakCategoryPack;
    if (cat == null || pack == null) return const SizedBox.shrink();
    return TrainingGapPromptBanner(category: cat, pack: pack);
  }
}
