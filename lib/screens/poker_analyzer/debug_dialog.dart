part of "../poker_analyzer_screen.dart";

class _DebugPanelDialog extends StatefulWidget {
  final PokerAnalyzerScreenState parent;

  const _DebugPanelDialog({required this.parent});

  @override
  State<_DebugPanelDialog> createState() => _DebugPanelDialogState();
}

class _DebugPanelDialogState extends State<_DebugPanelDialog> {
  PokerAnalyzerScreenState get s => widget.parent;

  static const _vGap = SizedBox(height: 12);
  static const _hGap = SizedBox(width: 8);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    s._debugPanelSetState = setState;
    s._processingService.debugPanelCallback = setState;
    _searchController.text = s._debugPrefs.searchQuery;
  }

  @override
  void dispose() {
    s._debugPanelSetState = null;
    s._processingService.debugPanelCallback = null;
    _searchController.dispose();
    super.dispose();
  }

  Widget _btn(String label, VoidCallback? onPressed,
      {bool disableDuringTransition = false}) {
    final cb = disableDuringTransition
        ? s.lockService.transitionSafe(onPressed)
        : onPressed;
    final disabled = disableDuringTransition && s._transitionHistory.isLocked;
    return ElevatedButton(onPressed: disabled ? null : cb, child: Text(label));
  }

  Widget _buttonsWrap(Map<String, VoidCallback?> actions,
      {bool transitionSafe = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in actions.entries)
          _btn(entry.key, entry.value,
              disableDuringTransition: transitionSafe),
      ],
    );
  }

class _QueueTools extends void StatelessWidget {
  const _QueueTools({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    final bool noQueues = s._queueService.pending.isEmpty &&
        s._queueService.failed.isEmpty &&
        s._queueService.completed.isEmpty;

    return state._buttonsWrap(<String, VoidCallback?>{
      'Import Evaluation Queue': s._importEvaluationQueue,
      'Restore Evaluation Queue': s._restoreEvaluationQueue,
      'Restore From Auto-Backup': s._restoreFromAutoBackup,
      'Bulk Import Evaluation Queue': s._bulkImportEvaluationQueue,
      'Bulk Import Backups': () async {
        await s._importExportService.bulkImportEvaluationBackups(s.context);
        if (s.mounted) s.lockService.safeSetState(s, () {});
        s._debugPanelSetState?.call(() {});
      },
      'Bulk Import Auto-Backups': () async {
        await s._importExportService.bulkImportAutoBackups(s.context);
        if (s.mounted) s.lockService.safeSetState(s, () {});
        s._debugPanelSetState?.call(() {});
      },
      'Import Queue Snapshot': s._importEvaluationQueueSnapshot,
      'Bulk Import Snapshots': s._bulkImportEvaluationSnapshots,
      'Export All Snapshots': s._exportAllEvaluationSnapshots,
      'Import Full Queue State': s._importFullEvaluationQueueState,
      'Restore Full Queue State': s._restoreFullEvaluationQueueState,
      'Export Full Queue State': s._exportFullEvaluationQueueState,
      'Export Queue To Clipboard': s._exportQueueToClipboard,
      'Import Queue From Clipboard': s._importQueueFromClipboard,
      'Export Current Queue Snapshot': s._exportEvaluationQueueSnapshot,
      'Quick Backup': s._quickBackupEvaluationQueue,
      'Import Quick Backups': () async {
        await s._importExportService.importQuickBackups(s.context);
        s._debugPanelSetState?.call(() {});
      },
      'Export All Backups': s._exportAllEvaluationBackups,
      'Clear Pending':
          s._queueService.pending.isEmpty ? null : s._clearPendingQueue,
      'Clear Failed':
          s._queueService.failed.isEmpty ? null : s._clearFailedQueue,
      'Clear Completed':
          s._queueService.completed.isEmpty ? null : s._clearCompletedQueue,
      'Clear Evaluation Queue': s._queueService.pending.isEmpty &&
              s._queueService.completed.isEmpty
          ? null
          : s._clearEvaluationQueue,
      'Remove Duplicates': noQueues ? null : s._removeDuplicateEvaluations,
      'Resolve Conflicts': noQueues ? null : s._resolveQueueConflicts,
      'Sort Queues': noQueues ? null : s._sortEvaluationQueues,
      'Clear Completed Evaluations':
          s._queueService.completed.isEmpty ? null : s._clearCompletedEvaluations,
    }, transitionSafe: true);
  }
}

class _SnapshotControls extends void StatelessWidget {
  const _SnapshotControls({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return state._buttonsColumn({
      'Retry Failed Evaluations':
          s._queueService.failed.isEmpty
              ? null
              : () async {
                  await s._processingService.retryFailedEvaluations();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Export Snapshot Now': s._processingService.processing
          ? null
          : () => s._exportEvaluationQueueSnapshot(showNotification: true),
      'Backup Queue Now': s._processingService.processing
          ? null
          : () async {
              await s._backupEvaluationQueue();
              s._debugPanelSetState?.call(() {});
            },
    }, transitionSafe: true);
  }
}

  Widget _buttonsColumn(Map<String, VoidCallback?> actions,
      {bool transitionSafe = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in actions.entries) ...[
          Align(
              alignment: Alignment.centerLeft,
              child: _btn(entry.key, entry.value,
                  disableDuringTransition: transitionSafe)),
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
          value: s._debugPrefs.snapshotRetentionEnabled,
          onChanged: (v) async {
            await s._debugPrefs.setSnapshotRetentionEnabled(v);
            if (v) await s._importExportService.cleanupOldEvaluationSnapshots();
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
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
          value: s._debugPrefs.sortBySpr,
          onChanged: (v) {
            s._debugPrefs.setSortBySpr(v);
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
          activeColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _pinHeroSwitch() {
    return Row(
      children: [
        const Expanded(child: Text('Pin Hero Position')),
        Switch(
          value: s._debugPrefs.pinHeroPosition,
          onChanged: (v) async {
            await s._debugPrefs.setPinHeroPosition(v);
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
          activeColor: Colors.orange,
        ),
      ],
    );
  }


class _ProcessingControls extends void StatelessWidget {
  const _ProcessingControls({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    final disabled = s._queueService.pending.isEmpty;
    return state._buttonsWrap({
      'Process Next':
          disabled || s._processingService.processing
              ? null
              : () async {
                  await s._processingService.processQueue();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Start Evaluation Processing':
          disabled || s._processingService.processing
              ? null
              : () async {
                  await s._processingService.processQueue();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      s._processingService.pauseRequested ? 'Resume' : 'Pause':
          disabled || !s._processingService.processing
              ? null
              : () async {
                  await s._processingService.togglePauseProcessing();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Cancel Evaluation Processing':
          !s._processingService.processing && disabled
              ? null
              : () async {
                  await s._processingService.cancelProcessing();
                  if (s.mounted) s.lockService.safeSetState(s, () {});
                },
      'Force Evaluation Restart': disabled
          ? null
          : () async {
              await s._processingService.forceRestartProcessing();
              if (s.mounted) s.lockService.safeSetState(s, () {});
            },
    });
  }
}

class _QueueDisplaySection extends void StatelessWidget {
  const _QueueDisplaySection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleButtons(
          isSelected: [
            s._debugPrefs.queueFilters.contains('pending'),
            s._debugPrefs.queueFilters.contains('failed'),
            s._debugPrefs.queueFilters.contains('completed'),
          ],
          onPressed: (i) {
            final modes = ['pending', 'failed', 'completed'];
            s._debugPrefs.toggleQueueFilter(modes[i]);
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
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
        _DebugPanelDialogState._vGap,
        ExpansionTile(
          title: const Text('Advanced Filters'),
          children: [
            CheckboxListTile(
              title: const Text('Only hands with feedback'),
              value: s._debugPrefs.advancedFilters.contains('feedback'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('feedback');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only hands with opponent cards'),
              value: s._debugPrefs.advancedFilters.contains('opponent'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('opponent');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only failed evaluations'),
              value: s._debugPrefs.advancedFilters.contains('failed'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('failed');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
            CheckboxListTile(
              title: const Text('Only high SPR (>=3)'),
              value: s._debugPrefs.advancedFilters.contains('highspr'),
              onChanged: (_) {
                s._debugPrefs.toggleAdvancedFilter('highspr');
                s.lockService.safeSetState(this, () {});
                s._debugPanelSetState?.call(() {});
              },
            ),
          ],
        ),
        _DebugPanelDialogState._vGap,
        state._sortBySprSwitch(),
        _DebugPanelDialogState._vGap,
        state._pinHeroSwitch(),
        _DebugPanelDialogState._vGap,
        TextField(
          controller: state._searchController,
          decoration:
              const InputDecoration(labelText: 'Search by ID or Feedback'),
          onChanged: (v) {
            s._debugPrefs.setSearchQuery(v);
            s.lockService.safeSetState(this, () {});
            s._debugPanelSetState?.call(() {});
          },
        ),
        _DebugPanelDialogState._vGap,
        Builder(
          builder: (context) {
            final sections = <Widget>[];
            if (s._debugPrefs.queueFilters.contains('pending')) {
              sections.add(state._queueSection('Pending', s._queueService.pending));
            }
            if (s._debugPrefs.queueFilters.contains('failed')) {
              sections.add(state._queueSection('Failed', s._queueService.failed));
            }
            if (s._debugPrefs.queueFilters.contains('completed')) {
              sections.add(
                  state._queueSection('Completed', s._queueService.completed));
            }
            if (sections.isEmpty) {
              return debugDiag('Queue Items', '(none)');
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
      ],
    );
  }
}

class _EvaluationResultsSection extends void StatelessWidget {
  const _EvaluationResultsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    final results = s._queueService.completed.length > 50
        ? s._queueService.completed
            .sublist(s._queueService.completed.length - 50)
        : s._queueService.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evaluation Results:'),
        if (results.isEmpty)
          debugDiag('Completed Evaluations', '(none)')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in results)
                debugDiag(
                    'Player ${r.playerIndex}, Street ${r.street}', r.action),
            ],
          ),
        _DebugPanelDialogState._vGap,
        const Text('Evaluation Queue Statistics:'),
        debugDiag('Pending', s._queueService.pending.length),
        debugDiag('Failed', s._queueService.failed.length),
        debugDiag('Completed', s._queueService.completed.length),
        debugDiag('Total Processed',
            s._queueService.completed.length + s._queueService.failed.length),
      ],
    );
  }
}

class _PlaybackDiagnosticsSection extends void StatelessWidget {
  const _PlaybackDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        debugDiag('Playback Index',
            '${s._playbackManager.playbackIndex} / ${s.actions.length}'),
        _DebugPanelDialogState._vGap,
        debugDiag('Active Player Index', s.activePlayerIndex ?? 'None'),
        _DebugPanelDialogState._vGap,
        debugDiag('Last Action Player Index',
            s._playbackManager.lastActionPlayerIndex ?? 'None'),
        _DebugPanelDialogState._vGap,
        const Text('Playback Pause State:'),
        debugDiag('Is Playback Paused', s._activeTimer == null),
      ],
    );
  }
}

class _HudOverlayDiagnosticsSection extends void StatelessWidget {
  const _HudOverlayDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    final hudStreetName = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][s.currentStreet];
    final hudPotText =
        ActionFormattingHelper.formatAmount(s._potSync.pots[s.currentStreet]);
    final int hudEffStack = s._potSync.calculateEffectiveStackForStreet(
        s.currentStreet, s.actions, s.numberOfPlayers);
    final double? hudSprValue = s._potSync.pots[s.currentStreet] > 0
        ? hudEffStack / s._potSync.pots[s.currentStreet]
        : null;
    final String? hudSprText =
        hudSprValue != null ? 'SPR: ${hudSprValue.toStringAsFixed(1)}' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HUD Overlay State:'),
        debugDiag('HUD Street Name', hudStreetName),
        _DebugPanelDialogState._vGap,
        debugDiag('HUD Pot Text', hudPotText),
        _DebugPanelDialogState._vGap,
        debugDiag('HUD SPR Text', hudSprText ?? '(none)'),
      ],
    );
  }
}

class _StreetTransitionDiagnosticsSection extends void StatelessWidget {
  const _StreetTransitionDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Street Transition State:'),
        debugDiag(
          'Current Animated Players Per Street',
          s._playbackManager.animatedPlayersPerStreet[s.currentStreet]?.length ??
              0,
        ),
        _DebugPanelDialogState._vGap,
        for (final entry
            in s._playbackManager.animatedPlayersPerStreet.entries) ...[
          debugDiag('Street ${entry.key} Animated Count', entry.value.length),
          _DebugPanelDialogState._vGap,
        ],
      ],
    );
  }
}

class _ChipTrailDiagnosticsSection extends void StatelessWidget {
  const _ChipTrailDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chip Trail Diagnostics:'),
        debugDiag('Animated Chips In Flight', ChipMovingWidget.activeCount),
      ],
    );
  }
}

class _EvaluationQueueDiagnosticsSection extends void StatelessWidget {
  const _EvaluationQueueDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        debugDiag(
          'Action Evaluation Queue',
          s._debugPrefs.queueResumed ? '(Resumed from saved state)' : '(New)',
        ),
        debugDiag('Pending Action Evaluations', s._queueService.pending.length),
        debugDiag(
          'Processed',
          '${s._queueService.completed.length} / ${s._queueService.pending.length + s._queueService.completed.length}',
        ),
        debugDiag('Failed', s._queueService.failed.length),
      ],
    );
  }
}

class _ExportConsistencySection extends void StatelessWidget {
  const _ExportConsistencySection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    final hand = s._currentSavedHand();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Debug Menu Visibility:'),
        debugDiag('Is Debug Menu Open', s._debugPrefs.isDebugPanelOpen),
        _DebugPanelDialogState._vGap,
        const Text('Full Export Consistency:'),
        debugCheck('numberOfPlayers',
            hand.numberOfPlayers == s.numberOfPlayers,
            '${hand.numberOfPlayers}', '${s.numberOfPlayers}'),
        debugCheck('heroIndex', hand.heroIndex == s.heroIndex,
            '${hand.heroIndex}', '${s.heroIndex}'),
        debugCheck('heroPosition', hand.heroPosition == s._heroPosition,
            hand.heroPosition, s._heroPosition),
        debugCheck('playerPositions',
            mapEquals(hand.playerPositions, s.playerPositions),
            hand.playerPositions.toString(),
            s.playerPositions.toString()),
        debugCheck('stackSizes',
            mapEquals(hand.stackSizes, s._stackService.initialStacks),
            hand.stackSizes.toString(),
            s._stackService.initialStacks.toString()),
        debugCheck('actions.length', hand.actions.length == s.actions.length,
            '${hand.actions.length}', '${s.actions.length}'),
        debugCheck(
            'boardCards',
            hand.boardCards.map((c) => c.toString()).join(' ') ==
                s.boardCards.map((c) => c.toString()).join(' '),
            hand.boardCards.map((c) => c.toString()).join(' '),
            s.boardCards.map((c) => c.toString()).join(' ')),
        debugCheck(
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
      ],
    );
  }
}

class _InternalStateFlagsSection extends void StatelessWidget {
  const _InternalStateFlagsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Internal State Flags:'),
        debugDiag('Debug Layout', s._debugPrefs.debugLayout),
        _DebugPanelDialogState._vGap,
        debugDiag('Perspective Switched', s.isPerspectiveSwitched),
        _DebugPanelDialogState._vGap,
        debugDiag('Show All Revealed Cards', s._debugPrefs.showAllRevealedCards),
        _DebugPanelDialogState._vGap,
        debugDiag('Pin Hero Position', s._debugPrefs.pinHeroPosition),
      ],
    );
  }
}

class _ThemeDiagnosticsSection extends void StatelessWidget {
  const _ThemeDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme Diagnostics:'),
        debugDiag('Current Theme',
            Theme.of(context).brightness == Brightness.dark ? 'Dark' : 'Light'),
      ],
    );
  }
}

class _CollapsedStreetsSection extends void StatelessWidget {
  const _CollapsedStreetsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Collapsed Streets State:'),
        for (int street = 0; street < 4; street++) ...[
          debugDiag(
            'Street \$street Collapsed',
            !s._actionHistory.expandedStreets.contains(street),
          ),
          _DebugPanelDialogState._vGap,
        ],
      ],
    );
  }
}

class _CenterChipDiagnosticsSection extends void StatelessWidget {
  const _CenterChipDiagnosticsSection({required this.state});

  final _DebugPanelDialogState state;

  @override
  Widget build(BuildContext context) {
    final PokerAnalyzerScreenState s = state.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chip Animation State:'),
        debugDiag(
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
        _DebugPanelDialogState._vGap,
        debugDiag('Show Center Chip', s._showCenterChip),
        _DebugPanelDialogState._vGap,
        const Text('Animation Controllers State:'),
        debugDiag('Center Chip Animation Active',
            s._centerChipController.isAnimating),
        _DebugPanelDialogState._vGap,
        debugDiag('Center Chip Animation Value',
            s._centerChipController.value.toStringAsFixed(2)),
      ],
    );
  }
}



  TextButton _dialogBtn(String label, VoidCallback? onPressed,
      {bool disableDuringTransition = false}) {
    final cb =
        disableDuringTransition ? s.lockService.transitionSafe(onPressed) : onPressed;
    final disabled = disableDuringTransition && s.lockService.isLocked;
    return TextButton(onPressed: disabled ? null : cb, child: Text(label));
  }

  Widget _queueSection(String label, List<ActionEvaluationRequest> queue) =>
      s._queueSection(label, queue);

  @override
  Widget build(BuildContext context) {
    final hand = s._currentSavedHand();

    return AlertDialog(
      title: const Text('Stack Diagnostics'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < s.numberOfPlayers; i++)
              debugDiag(
                'Player ${i + 1}',
                'Initial ${s._stackService.getInitialStack(i)}, '
                'Invested ${s._stackService.getTotalInvested(i)}, '
                'Remaining ${s._stackService.getStackForPlayer(i)}',
              ),
            _vGap,
            if (hand.remainingStacks != null) ...[
              const Text('Remaining Stacks (from saved hand):'),
              for (final entry in hand.remainingStacks!.entries)
                debugDiag('Player ${entry.key + 1}', entry.value),
              _vGap,
            ],
            if (hand.playerTypes != null) ...[
              const Text('Player Types:'),
              for (final entry in hand.playerTypes!.entries)
                debugDiag('Player ${entry.key + 1}', entry.value.name),
              _vGap,
            ],
            if (hand.comment != null) ...[
              debugDiag('Comment', hand.comment!),
              _vGap,
            ],
            if (hand.tags.isNotEmpty) ...[
              const Text('Tags:'),
              for (final tag in hand.tags) debugDiag('Tag', tag),
              _vGap,
            ],
            if (hand.opponentIndex != null) ...[
              debugDiag('Opponent', 'Player ${hand.opponentIndex! + 1}'),
              _vGap,
            ],
            debugDiag('Hero Position', hand.heroPosition),
            _vGap,
            debugDiag('Players at table', hand.numberOfPlayers),
            _vGap,
            debugDiag('Saved', formatDateTime(hand.date)),
            _vGap,
            if (hand.expectedAction != null) ...[
              debugDiag('Expected Action', hand.expectedAction),
              _vGap,
            ],
            if (hand.feedbackText != null) ...[
              debugDiag('Feedback', hand.feedbackText),
              _vGap,
            ],
            debugDiag(
              'Board Cards',
              s.boardCards.isNotEmpty
                  ? s.boardCards.map(s._cardToDebugString).join(' ')
                  : '(empty)',
            ),
            _vGap,
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              debugDiag(
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
            debugDiag('Current Street',
                ['Preflop', 'Flop', 'Turn', 'River'][s.currentStreet]),
            _vGap,
            _PlaybackDiagnosticsSection(state: this),
            _vGap,
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              debugDiag('Player ${i + 1} Cards', s.playerCards[i].length),
              _vGap,
            ],
            const Text('Effective Stacks:'),
            for (int street = 0; street < 4; street++)
              debugDiag(
                [
                  'Preflop',
                  'Flop',
                  'Turn',
                  'River',
                ][street],
                s._potSync.calculateEffectiveStackForStreet(
                    street, s.actions, s.numberOfPlayers),
              ),
            _vGap,
            const Text('Playback Diagnostics:'),
            debugDiag('Preflop Actions',
                s.actions.where((a) => a.street == 0).length),
            debugDiag('Flop Actions',
                s.actions.where((a) => a.street == 1).length),
            debugDiag('Turn Actions',
                s.actions.where((a) => a.street == 2).length),
            debugDiag('River Actions',
                s.actions.where((a) => a.street == 3).length),
            _vGap,
            debugDiag('Total Actions', s.actions.length),
            _vGap,
            const Text('Action Tags Diagnostics:'),
            if (s._actionTagService.toMap().isNotEmpty)
              for (final entry in s._actionTagService.toMap().entries) ...[
                debugDiag('Player ${entry.key + 1} Action Tag', entry.value),
                _vGap,
              ]
            else ...[
              debugDiag('Action Tags', '(none)'),
              _vGap,
            ],
            const Text('StackManager Diagnostics:'),
            for (int i = 0; i < s.numberOfPlayers; i++) ...[
              debugDiag(
                'Player $i StackManager',
                'current ${s._stackService.getStackForPlayer(i)}, invested ${s._stackService.getTotalInvested(i)}',
              ),
              _vGap,
            ],
            _InternalStateFlagsSection(state: this),
            _vGap,
            _snapshotRetentionSwitch(),
            _vGap,
            _CollapsedStreetsSection(state: this),
            _vGap,
            _CenterChipDiagnosticsSection(state: this),
            _vGap,
            _StreetTransitionDiagnosticsSection(state: this),
            _vGap,
            _ChipTrailDiagnosticsSection(state: this),
            _vGap,
            _EvaluationQueueDiagnosticsSection(state: this),
            _vGap,
            _QueueDisplaySection(state: this),
            _vGap,
            _ProcessingControls(state: this),
            _vGap,
            _SnapshotControls(state: this),
            _vGap,
            const Text('Evaluation Queue Tools:'),
            _QueueTools(state: this),
            _vGap,
            Row(
              children: [
                const Text('Processing Speed'),
                _hGap,
                Expanded(
                  child: Slider(
                    value: s._debugPrefs.processingDelay.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '${s._debugPrefs.processingDelay} ms',
                    onChanged: (v) async {
                      await s._debugPrefs.setProcessingDelay(v.round());
                      s.lockService.safeSetState(this, () {});
                      s._debugPanelSetState?.call(() {});
                    },
                  ),
                ),
                _hGap,
                debugDiag('Delay', '${s._debugPrefs.processingDelay} ms'),
              ],
            ),
            _vGap,
            _EvaluationResultsSection(state: this),
            _vGap,
            _HudOverlayDiagnosticsSection(state: this),
            _vGap,
            _ExportConsistencySection(state: this),
            _vGap,
            _ThemeDiagnosticsSection(state: this),
          ],
        ),
      ),
      actions: [
        _dialogBtn('Export Evaluation Queue', s._exportEvaluationQueue,
            disableDuringTransition: true),
        _dialogBtn('Export Full Queue State', s._exportFullEvaluationQueueState,
            disableDuringTransition: true),
        _dialogBtn('Export Queue To Clipboard', s._exportQueueToClipboard,
            disableDuringTransition: true),
        _dialogBtn('Import Queue From Clipboard', s._importQueueFromClipboard,
            disableDuringTransition: true),
        _dialogBtn('Export Spot To Clipboard', s.exportTrainingSpotToClipboard,
            disableDuringTransition: true),
        _dialogBtn('Import Spot From Clipboard', s.importTrainingSpotFromClipboard,
            disableDuringTransition: true),
        _dialogBtn('Export Spot To File', s.exportTrainingSpotToFile,
            disableDuringTransition: true),
        _dialogBtn('Import Spot From File', s.importTrainingSpotFromFile,
            disableDuringTransition: true),
        _dialogBtn('Export Spot Archive', s.exportTrainingArchive,
            disableDuringTransition: true),
        _dialogBtn('Export Profile To Clipboard',
            s.exportPlayerProfileToClipboard,
            disableDuringTransition: true),
        _dialogBtn('Import Profile From Clipboard',
            s.importPlayerProfileFromClipboard,
            disableDuringTransition: true),
        _dialogBtn('Export Profile To File', s.exportPlayerProfileToFile,
            disableDuringTransition: true),
        _dialogBtn('Import Profile From File', s.importPlayerProfileFromFile,
            disableDuringTransition: true),
        _dialogBtn('Export Profile Archive', s.exportPlayerProfileArchive,
            disableDuringTransition: true),
        _dialogBtn('Backup Evaluation Queue', s._backupEvaluationQueue,
            disableDuringTransition: true),
        _dialogBtn('Export All Backups', s._exportAllEvaluationBackups,
            disableDuringTransition: true),
        _dialogBtn('Export Auto-Backups', s._exportAutoBackups,
            disableDuringTransition: true),
        _dialogBtn('Export Snapshots', s._exportSnapshots,
            disableDuringTransition: true),
        _dialogBtn('Export All Snapshots', s._exportAllEvaluationSnapshots,
            disableDuringTransition: true),
        _dialogBtn('Previous Street',
            s.currentStreet <= 0 ? null : s._previousStreet,
            disableDuringTransition: true),
        _dialogBtn(
            'Next Street',
            s.currentStreet >= s.boardStreet
                ? null
                : s._nextStreet,
            disableDuringTransition: true),
        _dialogBtn(
          'Undo',
          s._transitionHistory.isLocked
              ? null
              : s._undoAction,
        ),
        _dialogBtn(
          'Redo',
          s._transitionHistory.isLocked
              ? null
              : s._redoAction,
        ),
        _dialogBtn('Previous Street', s._prevStreetDebug,
            disableDuringTransition: true),
        _dialogBtn('Next Street', s._nextStreetDebug,
            disableDuringTransition: true),
        _dialogBtn('Close', () => Navigator.pop(context)),
        _dialogBtn('Clear Evaluation Queue', s._clearEvaluationQueue),
        _dialogBtn('Reset Debug Panel Settings', s._resetDebugPanelPreferences),
      ],
    );
  }
