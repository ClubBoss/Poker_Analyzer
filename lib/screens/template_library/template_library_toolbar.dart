part of '../template_library_screen.dart';

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
