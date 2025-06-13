part of '../screens/poker_analyzer_screen.dart';

class DebugPanel extends StatefulWidget {
  final _PokerAnalyzerScreenState parent;

  const DebugPanel({required this.parent});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  _PokerAnalyzerScreenState get s => widget.parent;

  static const _vGap = SizedBox(height: 12);
  static const _hGap = SizedBox(width: 8);

  final TextEditingController _searchController = TextEditingController();

  Widget _diag(String label, Object? value) => debugDiag(label, value);
  Widget _check(String label, bool ok, String a, String b) =>
      debugCheck(label, ok, a, b);
  Widget _queueSection(String label, List<ActionEvaluationRequest> queue) {
    final filtered = s._applyAdvancedFilters(queue);
    return debugQueueSection(
      label,
      filtered,
      s._advancedFilters.isEmpty && !s._sortBySpr && s._searchQuery.isEmpty
          ? (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              setState(() {
                final item = queue.removeAt(oldIndex);
                queue.insert(newIndex, item);
              });
              s._persistEvaluationQueue();
              s._debugPanelSetState?.call(() {});
            }
          : (_, __) {},
    );
  }

  @override
  void initState() {
    super.initState();
    s._debugPanelSetState = setState;
    _searchController.text = s._searchQuery;
  }

  @override
  void dispose() {
    s._debugPanelSetState = null;
    _searchController.dispose();
    super.dispose();
  }

  Widget _btn(String label, VoidCallback? onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }

  Widget _buttonsWrap(Map<String, VoidCallback?> actions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in actions.entries) _btn(entry.key, entry.value),
      ],
    );
  }

  Widget _buttonsColumn(Map<String, VoidCallback?> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in actions.entries) ...[
          Align(alignment: Alignment.centerLeft, child: _btn(entry.key, entry.value)),
          if (entry.key != actions.keys.last) _vGap,
        ],
      ],
    );
  }

  Widget _snapshotRetentionSwitch() {
    return Row(
      children: [
        const Expanded(child: Text('Enable Snapshot Retention Policy')),
        Switch(
          value: s._snapshotRetentionEnabled,
          onChanged: s._setSnapshotRetentionEnabled,
          activeColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _sortBySprSwitch() {
    return Row(
      children: [
        const Expanded(child: Text('Sort by SPR')),
        Switch(
          value: s._sortBySpr,
          onChanged: s._setSortBySpr,
          activeColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _processingControls() {
    final disabled = s._pendingEvaluations.isEmpty;
    return _buttonsWrap({
      'Process Next':
          disabled || s._processingEvaluations ? null : s._processNextEvaluation,
      'Start Evaluation Processing':
          disabled || s._processingEvaluations ? null : s._processEvaluationQueue,
      s._pauseProcessingRequested ? 'Resume' : 'Pause':
          disabled || !s._processingEvaluations ? null : s._toggleEvaluationProcessingPause,
      'Cancel Evaluation Processing':
          !s._processingEvaluations && disabled ? null : s._cancelEvaluationProcessing,
      'Force Evaluation Restart': disabled ? null : s._forceRestartEvaluationProcessing,
    });
  }

  Widget _snapshotControls() {
    return _buttonsColumn({
      'Retry Failed Evaluations':
          s._failedEvaluations.isEmpty ? null : s._retryFailedEvaluations,
      'Export Snapshot Now': s._processingEvaluations
          ? null
          : () => s._exportEvaluationQueueSnapshot(showNotification: true),
      'Backup Queue Now': s._processingEvaluations
          ? null
          : () async {
              await s._backupEvaluationQueue();
              s._debugPanelSetState?.call(() {});
            },
    });
  }

  Widget _queueTools() {
    final noQueues =
        s._pendingEvaluations.isEmpty && s._failedEvaluations.isEmpty && s._completedEvaluations.isEmpty;
    return _buttonsWrap({
      'Import Evaluation Queue': s._importEvaluationQueue,
      'Restore Evaluation Queue': s._restoreEvaluationQueue,
      'Restore From Auto-Backup': s._restoreFromAutoBackup,
      'Bulk Import Evaluation Queue': s._bulkImportEvaluationQueue,
      'Bulk Import Backups': s._bulkImportEvaluationBackups,
      'Bulk Import Auto-Backups': s._bulkImportAutoBackups,
      'Import Queue Snapshot': s._importEvaluationQueueSnapshot,
      'Bulk Import Snapshots': s._bulkImportEvaluationSnapshots,
      'Export All Snapshots': s._exportAllEvaluationSnapshots,
      'Import Full Queue State': s._importFullEvaluationQueueState,
      'Restore Full Queue State': s._restoreFullEvaluationQueueState,
      'Export Full Queue State': s._exportFullEvaluationQueueState,
      'Export Current Queue Snapshot': s._exportEvaluationQueueSnapshot,
      'Quick Backup': s._quickBackupEvaluationQueue,
      'Import Quick Backups': s._importQuickBackups,
      'Export All Backups': s._exportAllEvaluationBackups,
      'Clear Pending': s._pendingEvaluations.isEmpty ? null : s._clearPendingQueue,
      'Clear Failed': s._failedEvaluations.isEmpty ? null : s._clearFailedQueue,
      'Clear Completed': s._completedEvaluations.isEmpty ? null : s._clearCompletedQueue,
      'Clear Evaluation Queue':
          s._pendingEvaluations.isEmpty && s._completedEvaluations.isEmpty ? null : s._clearEvaluationQueue,
      'Remove Duplicates': noQueues ? null : s._removeDuplicateEvaluations,
      'Resolve Conflicts': noQueues ? null : s._resolveQueueConflicts,
      'Sort Queues': noQueues ? null : s._sortEvaluationQueues,
      'Clear Completed Evaluations':
          s._completedEvaluations.isEmpty ? null : s._clearCompletedEvaluations,
    });
  }

  TextButton _dialogBtn(String label, VoidCallback onPressed) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    final hand = s._currentSavedHand();
    final hudStreetName = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][s.currentStreet];
    final hudPotText = s._formatAmount(s._pots[s.currentStreet]);
    final int hudEffStack =
        s._calculateEffectiveStackForStreet(s.currentStreet);
    final double? hudSprValue = s._pots[s.currentStreet] > 0
        ? hudEffStack / s._pots[s.currentStreet]
        : null;
    final String? hudSprText =
        hudSprValue != null ? 'SPR: ${hudSprValue.toStringAsFixed(1)}' : null;

    return AlertDialog(
      title: const Text('Stack Diagnostics'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < s.numberOfPlayers; i++)
              _diag(
                'Player ${i + 1}',
                'Initial ${s._initialStacks[i] ?? 0}, '
                'Invested ${s._stackManager.getTotalInvested(i)}, '
                'Remaining ${s._stackManager.getStackForPlayer(i)}',
              ),
            _vGap,
            if (hand.remainingStacks != null) ...[
              const Text('Remaining Stacks (from saved hand):'),
              for (final entry in hand.remainingStacks!.entries)
                _diag('Player ${entry.key + 1}', entry.value),
              _vGap,
            ],
            if (hand.playerTypes != null) ...[
              const Text('Player Types:'),
              for (final entry in hand.playerTypes!.entries)
                _diag('Player ${entry.key + 1}', entry.value.name),
              _vGap,
            ],
            if (hand.comment != null) ...[
              _diag('Comment', hand.comment!),
              _vGap,
            ],
            if (hand.tags.isNotEmpty) ...[
              const Text('Tags:'),
              for (final tag in hand.tags) _diag('Tag', tag),
              _vGap,
            ],
            if (hand.opponentIndex != null) ...[
              _diag('Opponent', 'Player ${hand.opponentIndex! + 1}'),
              _vGap,
            ],
            _diag('Hero Position', hand.heroPosition),
            _vGap,
            _diag('Players at table', hand.numberOfPlayers),
            _vGap,
            _diag('Saved', formatDateTime(hand.date)),
            _vGap,
            if (hand.expectedAction != null) ...[
              _diag('Expected Action', hand.expectedAction),
              _vGap,
            ],
            if (hand.feedbackText != null) ...[
              _diag('Feedback', hand.feedbackText),
              _vGap,
            ],
            _diag(
              'Board Cards',
              s.boardCards.isNotEmpty
                  ? s.boardCards.map(s._cardToDebugString).join(' ')
                  : '(empty)',
            ),
            _vGap,
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              _diag(
                'Player ${i + 1} Revealed',
                () {
                  final rc =
                      i < hand.revealedCards.length ? hand.revealedCards[i] : [];
                  return rc.isNotEmpty
                      ? rc.map(s._cardToDebugString).join(' ')
                      : '(none)';
                }(),
              ),
              _vGap,
            ],
            _diag('Current Street',
                ['Preflop', 'Flop', 'Turn', 'River'][s.currentStreet]),
            _vGap,
            _diag('Playback Index', '${s._playbackIndex} / ${s.actions.length}'),
            _vGap,
            _diag('Active Player Index', s.activePlayerIndex ?? 'None'),
            _vGap,
            _diag('Last Action Player Index', s.lastActionPlayerIndex ?? 'None'),
            _vGap,
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              _diag('Player ${i + 1} Cards', s.playerCards[i].length),
              _vGap,
            ],
            _diag(
              'First Action Taken',
              s._firstActionTaken.isNotEmpty
                  ? (s._firstActionTaken.toList()..sort()).join(', ')
                  : '(none)',
            ),
            _vGap,
            const Text('Effective Stacks:'),
            for (int street = 0; street < 4; street++)
              _diag(
                [
                  'Preflop',
                  'Flop',
                  'Turn',
                  'River',
                ][street],
                s._calculateEffectiveStackForStreet(street),
              ),
            _vGap,
            const Text('Effective Stacks (from export data):'),
            if (s._savedEffectiveStacks != null)
              for (final entry in s._savedEffectiveStacks!.entries)
                _diag(entry.key, entry.value)
            else
              _diag('Export Data', '(none)'),
            if (s._savedEffectiveStacks != null) ...[
              _vGap,
              const Text('Validation:'),
              for (int st = 0; st < 4; st++)
                () {
                  const names = ['Preflop', 'Flop', 'Turn', 'River'];
                  final name = names[st];
                  final live = s._calculateEffectiveStackForStreet(st);
                  final exported = s._savedEffectiveStacks![name];
                  final ok = exported == live;
                  return _diag(
                    name,
                    ok ? '✅' : '❌ live $live vs export ${exported ?? 'N/A'}',
                  );
                }(),
            ],
            if (s._validationNotes != null && s._validationNotes!.isNotEmpty) ...[
              _vGap,
              const Text('Validation Notes:'),
              for (final entry in s._validationNotes!.entries)
                _diag(entry.key, entry.value),
            ],
            _vGap,
            const Text('Playback Diagnostics:'),
            _diag('Preflop Actions',
                s.actions.where((a) => a.street == 0).length),
            _diag('Flop Actions',
                s.actions.where((a) => a.street == 1).length),
            _diag('Turn Actions',
                s.actions.where((a) => a.street == 2).length),
            _diag('River Actions',
                s.actions.where((a) => a.street == 3).length),
            _vGap,
            _diag('Total Actions', s.actions.length),
            _vGap,
            const Text('Action Tags Diagnostics:'),
            if (s._actionTags.isNotEmpty)
              for (final entry in s._actionTags.entries) ...[
                _diag('Player ${entry.key + 1} Action Tag', entry.value),
                _vGap,
              ]
            else ...[
              _diag('Action Tags', '(none)'),
              _vGap,
            ],
            const Text('StackManager Diagnostics:'),
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              _diag(
                'Player $i StackManager',
                'current ${s._stackManager.getStackForPlayer(i)}, invested ${s._stackManager.getTotalInvested(i)}',
              ),
              _vGap,
            ],
            const Text('Internal State Flags:'),
            _diag('Debug Layout', s.debugLayout),
            _vGap,
            _diag('Perspective Switched', s.isPerspectiveSwitched),
            _vGap,
            _diag('Show All Revealed Cards', s._showAllRevealedCards),
            _vGap,
            _snapshotRetentionSwitch(),
            _vGap,
            const Text('Collapsed Streets State:'),
            for (int street = 0; street < 4; street++) ...[
              _diag(
                'Street $street Collapsed',
                !s._expandedHistoryStreets.contains(street),
              ),
              _vGap,
            ],
            const Text('Chip Animation State:'),
            _diag(
              'Center Chip Action',
              () {
                final action = s._centerChipAction;
                if (action == null) return '(null)';
                var result =
                    'Street ${action.street}, Player ${action.playerIndex}, Action ${action.action}';
                if (action.amount != null) result += ', Amount ${action.amount}';
                return result;
              }(),
            ),
            _vGap,
            _diag('Show Center Chip', s._showCenterChip),
            _vGap,
            const Text('Animation Controllers State:'),
            _diag('Center Chip Animation Active',
                s._centerChipController.isAnimating),
            _vGap,
            _diag('Center Chip Animation Value',
                s._centerChipController.value.toStringAsFixed(2)),
            _vGap,
            const Text('Street Transition State:'),
            _diag(
              'Current Animated Players Per Street',
              s._animatedPlayersPerStreet[s.currentStreet]?.length ?? 0,
            ),
            _vGap,
            for (final entry in s._animatedPlayersPerStreet.entries) ...[
              _diag('Street ${entry.key} Animated Count', entry.value.length),
              _vGap,
            ],
            const Text('Chip Trail Diagnostics:'),
            _diag('Animated Chips In Flight', ChipMovingWidget.activeCount),
            _vGap,
            const Text('Playback Pause State:'),
            _diag('Is Playback Paused', s._activeTimer == null),
            _vGap,
            _diag(
              'Action Evaluation Queue',
              s._evaluationQueueResumed
                  ? '(Resumed from saved state)'
                  : '(New)',
            ),
            _diag('Pending Action Evaluations', s._pendingEvaluations.length),
            _diag(
                'Processed',
                '${s._completedEvaluations.length} / ${s._pendingEvaluations.length + s._completedEvaluations.length}'),
            _diag('Failed', s._failedEvaluations.length),
            _vGap,
            ToggleButtons(
              isSelected: [
                s._queueFilters.contains('pending'),
                s._queueFilters.contains('failed'),
                s._queueFilters.contains('completed'),
              ],
              onPressed: (i) {
                final modes = ['pending', 'failed', 'completed'];
                s._toggleQueueFilter(modes[i]);
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Pending'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Failed'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Completed'),
                ),
              ],
            ),
            _vGap,
            ExpansionTile(
              title: const Text('Advanced Filters'),
              children: [
                CheckboxListTile(
                  title: const Text('Only hands with feedback'),
                  value: s._advancedFilters.contains('feedback'),
                  onChanged: (_) => s._toggleAdvancedFilter('feedback'),
                ),
                CheckboxListTile(
                  title: const Text('Only hands with opponent cards'),
                  value: s._advancedFilters.contains('opponent'),
                  onChanged: (_) => s._toggleAdvancedFilter('opponent'),
                ),
                CheckboxListTile(
                  title: const Text('Only failed evaluations'),
                  value: s._advancedFilters.contains('failed'),
                  onChanged: (_) => s._toggleAdvancedFilter('failed'),
                ),
                CheckboxListTile(
                  title: const Text('Only high SPR (>=3)'),
                  value: s._advancedFilters.contains('highspr'),
                  onChanged: (_) => s._toggleAdvancedFilter('highspr'),
                ),
              ],
            ),
            _vGap,
            _sortBySprSwitch(),
            _vGap,
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                  labelText: 'Search by ID or Feedback'),
              onChanged: (v) => s._setSearchQuery(v),
            ),
            _vGap,
            Builder(
              builder: (context) {
                final sections = <Widget>[];
                if (s._queueFilters.contains('pending')) {
                  sections.add(_queueSection('Pending', s._pendingEvaluations));
                }
                if (s._queueFilters.contains('failed')) {
                  sections.add(_queueSection('Failed', s._failedEvaluations));
                }
                if (s._queueFilters.contains('completed')) {
                  sections.add(_queueSection('Completed', s._completedEvaluations));
                }
                if (sections.isEmpty) {
                  return _diag('Queue Items', '(none)');
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sections,
                    ),
                  ),
                );
              },
            ),
            _vGap,
            _processingControls(),
            _vGap,
            _snapshotControls(),
            _vGap,
            const Text('Evaluation Queue Tools:'),
            _queueTools(),
            _vGap,
            Row(
              children: [
                const Text('Processing Speed'),
                _hGap,
                Expanded(
                  child: Slider(
                    value: s._evaluationProcessingDelay.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '${s._evaluationProcessingDelay} ms',
                    onChanged: (v) {
                      s._setProcessingDelay(v.round());
                    },
                  ),
                ),
                _hGap,
                _diag('Delay', '${s._evaluationProcessingDelay} ms'),
              ],
            ),
            _vGap,
            const Text('Evaluation Results:'),
            Builder(
              builder: (context) {
                final results = s._completedEvaluations.length > 50
                    ? s._completedEvaluations
                        .sublist(s._completedEvaluations.length - 50)
                    : s._completedEvaluations;
                if (results.isEmpty) {
                  return _diag('Completed Evaluations', '(none)');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final r in results)
                      _diag('Player ${r.playerIndex}, Street ${r.street}', r.action),
                  ],
                );
              },
            ),
            _vGap,
            const Text('Evaluation Queue Statistics:'),
            _diag('Pending', s._pendingEvaluations.length),
            _diag('Failed', s._failedEvaluations.length),
            _diag('Completed', s._completedEvaluations.length),
            _diag('Total Processed',
                s._completedEvaluations.length + s._failedEvaluations.length),
            _vGap,
            const Text('HUD Overlay State:'),
            _diag('HUD Street Name', hudStreetName),
            _vGap,
            _diag('HUD Pot Text', hudPotText),
            _vGap,
            _diag('HUD SPR Text', hudSprText ?? '(none)'),
            _vGap,
            const Text('Debug Menu Visibility:'),
            _diag('Is Debug Menu Open', s._isDebugPanelOpen),
            _vGap,
            const Text('Full Export Consistency:'),
            _check('numberOfPlayers',
                hand.numberOfPlayers == s.numberOfPlayers,
                '${hand.numberOfPlayers}', '${s.numberOfPlayers}'),
            _check('heroIndex', hand.heroIndex == s.heroIndex,
                '${hand.heroIndex}', '${s.heroIndex}'),
            _check('heroPosition', hand.heroPosition == s._heroPosition,
                hand.heroPosition, s._heroPosition),
            _check('playerPositions',
                mapEquals(hand.playerPositions, s.playerPositions),
                hand.playerPositions.toString(),
                s.playerPositions.toString()),
            _check('stackSizes', mapEquals(hand.stackSizes, s._initialStacks),
                hand.stackSizes.toString(), s._initialStacks.toString()),
            _check('actions.length', hand.actions.length == s.actions.length,
                '${hand.actions.length}', '${s.actions.length}'),
            _check(
                'boardCards',
                hand.boardCards.map((c) => c.toString()).join(' ') ==
                    s.boardCards.map((c) => c.toString()).join(' '),
                hand.boardCards.map((c) => c.toString()).join(' '),
                s.boardCards.map((c) => c.toString()).join(' ')),
            _check(
                'revealedCards',
                listEquals(
                  [
                    for (final p in s.players)
                      p.revealedCards
                          .whereType<CardModel>()
                          .map((c) => c.toString())
                          .join(' ')
                  ],
                  [
                    for (final list in hand.revealedCards)
                      list.map((c) => c.toString()).join(' ')
                  ],
                ),
                [
                  for (final list in hand.revealedCards)
                    list.map((c) => c.toString()).join(' ')
                ].toString(),
                [
                  for (final p in s.players)
                    p.revealedCards
                        .whereType<CardModel>()
                        .map((c) => c.toString())
                        .join(' ')
                ].toString()),
            _vGap,
            const Text('Theme Diagnostics:'),
            _diag('Current Theme',
                Theme.of(context).brightness == Brightness.dark ? 'Dark' : 'Light'),
            _vGap,
          ],
        ),
      ),
      actions: [
        _dialogBtn('Export Evaluation Queue', s._exportEvaluationQueue),
        _dialogBtn('Export Full Queue State', s._exportFullEvaluationQueueState),
        _dialogBtn('Backup Evaluation Queue', s._backupEvaluationQueue),
        _dialogBtn('Export All Backups', s._exportAllEvaluationBackups),
        _dialogBtn('Export Auto-Backups', s._exportAutoBackups),
        _dialogBtn('Export Snapshots', s._exportSnapshots),
        _dialogBtn('Export All Snapshots', s._exportAllEvaluationSnapshots),
        _dialogBtn('Close', () => Navigator.pop(context)),
        _dialogBtn('Clear Evaluation Queue', s._clearEvaluationQueue),
        _dialogBtn('Reset Debug Panel Settings', s._resetDebugPanelPreferences),
      ],
    );
  }
}
