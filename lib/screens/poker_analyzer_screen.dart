import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/board_cards_widget.dart';
import '../widgets/detailed_action_bottom_sheet.dart';
import '../widgets/chip_widget.dart';
import '../widgets/street_actions_list.dart';
import '../widgets/collapsible_street_summary.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/chip_trail.dart';
import '../widgets/bet_chips_on_table.dart';
import '../widgets/invested_chip_tokens.dart';
import '../widgets/central_pot_widget.dart';
import '../widgets/central_pot_chips.dart';
import '../helpers/poker_position_helper.dart';
import '../models/saved_hand.dart';

class PokerAnalyzerScreen extends StatefulWidget {
  const PokerAnalyzerScreen({super.key});

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen> {
  int heroIndex = 0;
  String _heroPosition = 'BTN';
  int numberOfPlayers = 6;
  final List<List<CardModel>> playerCards = List.generate(9, (_) => []);
  final List<CardModel> boardCards = [];
  int currentStreet = 0;
  final List<ActionEntry> actions = [];
  int _playbackIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  final List<int> _pots = List.filled(4, 0);
  final Map<int, Map<int, int>> _streetInvestments = {};
  final Map<int, int> stackSizes = {
    0: 120,
    1: 80,
    2: 100,
    3: 90,
    4: 110,
    5: 70,
    6: 130,
    7: 95,
    8: 105,
  };
  final TextEditingController _commentController = TextEditingController();
  final List<bool> _showActionHints = List.filled(9, true);
  final Set<int> _firstActionTaken = {};
  int? activePlayerIndex;
  int? lastActionPlayerIndex;
  Timer? _activeTimer;
  final Map<int, String?> _actionTags = {};
  Map<int, String> playerPositions = {};
  Map<int, String> playerTypes = {};

  bool debugLayout = false;

  List<String> _positionsForPlayers(int count) {
    return getPositionList(count);
  }

  void setPosition(int playerIndex, String position) {
    setState(() {
      playerPositions[playerIndex] = position;
    });
  }

  void _updatePositions() {
    final order = _positionsForPlayers(numberOfPlayers);
    final heroPosIndex = order.indexOf(_heroPosition);
    final buttonIndex =
        (heroIndex - heroPosIndex + numberOfPlayers) % numberOfPlayers;
    playerPositions = {};
    for (int i = 0; i < numberOfPlayers; i++) {
      final posIndex = (i - buttonIndex + numberOfPlayers) % numberOfPlayers;
      if (posIndex < order.length) {
        playerPositions[i] = order[posIndex];
      }
    }
  }

  double _verticalBiasFromAngle(double angle) {
    return 90 + 20 * sin(angle);
  }

  String _formatAmount(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'fold':
        return Colors.red[700]!;
      case 'call':
        return Colors.blue[700]!;
      case 'raise':
        return Colors.green[600]!;
      case 'bet':
        return Colors.amber[700]!;
      case 'check':
        return Colors.grey[700]!;
      default:
        return Colors.black;
    }
  }

  Color _actionTextColor(String action) {
    switch (action) {
      case 'bet':
        return Colors.black;
      default:
        return Colors.white;
    }
  }

  IconData? _actionIcon(String action) {
    switch (action) {
      case 'fold':
        return Icons.close;
      case 'call':
        return Icons.call;
      case 'raise':
        return Icons.arrow_upward;
      case 'bet':
        return Icons.trending_up;
      case 'check':
        return Icons.remove;
      default:
        return null;
    }
  }

  String _actionLabel(ActionEntry entry) {
    return entry.amount != null
        ? '${entry.action} ${entry.amount}'
        : entry.action;
  }

  String _playerTypeIcon(String? type) {
    switch (type) {
      case 'shark':
        return '🦈';
      case 'fish':
        return '🐟';
      case 'nit':
        return '🧊';
      case 'maniac':
        return '🔥';
      case 'station':
        return '📞';
      default:
        return '🔘';
    }
  }

  String _evaluateActionQuality(ActionEntry entry) {
    switch (entry.action) {
      case 'raise':
      case 'bet':
        return 'good';
      case 'call':
      case 'check':
        return 'ok';
      case 'fold':
        return 'bad';
      default:
        return 'ok';
    }
  }

  Future<void> _selectPlayerType(int index) async {
    const types = {
      'shark': '🦈',
      'fish': '🐟',
      'nit': '🧊',
      'maniac': '🔥',
      'station': '📞',
      'standard': '🔘',
    };
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Тип игрока'),
        children: [
          for (final entry in types.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.value, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(entry.key),
                ],
              ),
            ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        playerTypes[index] = result;
      });
    }
  }

  Future<void> _chooseHeroPosition() async {
    final options = _positionsForPlayers(numberOfPlayers);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выбрать позицию Hero'),
        children: [
          for (final pos in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, pos),
              child: Text(pos),
            ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _heroPosition = result;
        _updatePositions();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    playerPositions = Map.fromIterables(
      List.generate(numberOfPlayers, (i) => i),
      getPositionList(numberOfPlayers),
    );
    playerTypes = Map.fromIterables(
      List.generate(numberOfPlayers, (i) => i),
      List.filled(numberOfPlayers, 'standard'),
    );
    _updatePositions();
    _updatePlaybackState();
  }

  void selectCard(int index, CardModel card) {
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == card);
      }
      boardCards.removeWhere((c) => c == card);
      if (playerCards[index].length < 2) {
        playerCards[index].add(card);
      }
    });
  }

  void selectBoardCard(int index, CardModel card) {
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == card);
      }
      boardCards.removeWhere((c) => c == card);
      if (index < boardCards.length) {
        boardCards[index] = card;
      } else if (index == boardCards.length) {
        boardCards.add(card);
      }
    });
  }

  int _calculateCallAmount(int playerIndex, {List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    final streetActions =
        list.where((a) => a.street == currentStreet).toList();
    final Map<int, int> bets = {};
    int highest = 0;
    for (final a in streetActions) {
      if (a.action == 'bet' || a.action == 'raise' || a.action == 'call') {
        bets[a.playerIndex] = (bets[a.playerIndex] ?? 0) + (a.amount ?? 0);
        highest = max(highest, bets[a.playerIndex]!);
      }
    }
    final playerBet = bets[playerIndex] ?? 0;
    return max(0, highest - playerBet);
  }

  bool _streetHasBet({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    return list
        .where((a) => a.street == currentStreet)
        .any((a) => a.action == 'bet' || a.action == 'raise');
  }

  int _calculatePotForStreet(int street, {List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    int pot = 0;
    for (int s = 0; s <= street; s++) {
      pot += list
          .where((a) => a.street == s &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise'))
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
    }
    return pot;
  }

  void _recalculatePots({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    int cumulative = 0;
    for (int s = 0; s < _pots.length; s++) {
      final streetAmount = list
          .where((a) => a.street == s &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise'))
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
      cumulative += streetAmount;
      _pots[s] = cumulative;
    }
  }

  void _recalculateStreetInvestments({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    _streetInvestments.clear();
    for (final a in list) {
      if (a.action == 'call' || a.action == 'bet' || a.action == 'raise') {
        final streetMap = _streetInvestments.putIfAbsent(a.street, () => {});
        streetMap[a.playerIndex] =
            (streetMap[a.playerIndex] ?? 0) + (a.amount ?? 0);
      }
      // Do not remove chip contributions on "fold" so that
      // folded players still display their invested amount
    }
  }

  int _calculateEffectiveStack({List<ActionEntry>? fromActions}) {
    final list = fromActions ?? actions;
    int? minStack;
    for (final entry in stackSizes.entries) {
      final index = entry.key;
      final folded = list.any((a) =>
          a.playerIndex == index && a.action == 'fold' && a.street <= currentStreet);
      if (folded) continue;
      final stack = entry.value;
      if (minStack == null || stack < minStack) {
        minStack = stack;
      }
    }
    return minStack ?? 0;
  }

  void _updatePlaybackState() {
    final subset = actions.take(_playbackIndex).toList();
    _recalculatePots(fromActions: subset);
    _recalculateStreetInvestments(fromActions: subset);
    lastActionPlayerIndex =
        subset.isNotEmpty ? subset.last.playerIndex : null;
  }

  void _playStepForward() {
    if (_playbackIndex < actions.length) {
      setState(() {
        _playbackIndex++;
      });
      _updatePlaybackState();
    } else {
      _pausePlayback();
    }
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _isPlaying = false;
  }

  void _startPlayback() {
    _pausePlayback();
    setState(() {
      _isPlaying = true;
      if (_playbackIndex == actions.length) {
        _playbackIndex = 0;
      }
    });
    _updatePlaybackState();
    _playbackTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _playStepForward());
  }

  void _stepForward() {
    _pausePlayback();
    _playStepForward();
  }

  void _stepBackward() {
    _pausePlayback();
    if (_playbackIndex > 0) {
      setState(() {
        _playbackIndex--;
      });
      _updatePlaybackState();
    }
  }

  void _addAutoFolds(ActionEntry entry) {
    final street = entry.street;
    final ordered =
        List.generate(numberOfPlayers, (i) => (i + heroIndex) % numberOfPlayers);
    final acted = actions
        .where((a) => a.street == street)
        .map((a) => a.playerIndex)
        .toSet();
    final toFold = ordered
        .takeWhile((i) => i != entry.playerIndex)
        .where((i) => !acted.contains(i));

    bool inserted = false;
    for (final i in toFold) {
      final autoFold = ActionEntry(street, i, 'fold', generated: true);
      _addAction(autoFold);
      inserted = true;
    }
    if (inserted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пропущенные игроки сброшены в пас.')),
      );
    }
  }

  void _applyStackChange(ActionEntry entry, {bool revert = false}) {
    if (entry.action == 'call' ||
        entry.action == 'bet' ||
        entry.action == 'raise') {
      final amount = entry.amount ?? 0;
      final current = stackSizes[entry.playerIndex] ?? 0;
      stackSizes[entry.playerIndex] = revert ? current + amount : current - amount;
    }
  }

  void _addAction(ActionEntry entry) {
    actions.add(entry);
    _applyStackChange(entry);
    lastActionPlayerIndex = entry.playerIndex;
    _actionTags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
    _recalculatePots();
    _recalculateStreetInvestments();
    _updatePlaybackState();
  }

  void onActionSelected(ActionEntry entry) {
    setState(() {
      _addAutoFolds(entry);
      _addAction(entry);
    });
  }

  void _updateAction(int index, ActionEntry entry) {
    final old = actions[index];
    _applyStackChange(old, revert: true);
    actions[index] = entry;
    _applyStackChange(entry);
    _recalculatePots();
    _recalculateStreetInvestments();
    if (index == actions.length - 1) {
      lastActionPlayerIndex = entry.playerIndex;
    }
    _actionTags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
    _updatePlaybackState();
  }

  void _editAction(int index, ActionEntry entry) {
    setState(() {
      _updateAction(index, entry);
    });
  }

  Future<void> _editStackSize(int index) async {
    final controller =
        TextEditingController(text: (stackSizes[index] ?? 0).toString());
    int? value = stackSizes[index];
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(
              'Стек игрока ${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Введите стек',
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              onChanged: (text) {
                setState(() => value = int.tryParse(text));
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: value != null && value! > 0
                    ? () => Navigator.pop(context, value)
                    : null,
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null) {
      setState(() {
        stackSizes[index] = result;
      });
    }
  }

  void _showStreetActionsDetails() {
    final streetActions =
        actions.where((a) => a.street == currentStreet).toList(growable: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][currentStreet],
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final a in streetActions)
                ListTile(
                  dense: true,
                  title: Text(
                    '${playerPositions[a.playerIndex] ?? 'Player ${a.playerIndex + 1}'} '
                    '— ${a.action}${a.amount != null ? ' ${a.amount}' : ''}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteAction(int index) {
    setState(() {
      final removed = actions.removeAt(index);
      _applyStackChange(removed, revert: true);
      _recalculatePots();
      _recalculateStreetInvestments();
      lastActionPlayerIndex = actions.isNotEmpty ? actions.last.playerIndex : null;
      if (_playbackIndex > actions.length) {
        _playbackIndex = actions.length;
      }
      _updatePlaybackState();
    });
  }

  Future<void> _resetHand() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить раздачу?'),
        content: const Text('Все введённые данные будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        for (final list in playerCards) {
          list.clear();
        }
        boardCards.clear();
        actions.clear();
        currentStreet = 0;
        _pots.fillRange(0, _pots.length, 0);
        _streetInvestments.clear();
        _actionTags.clear();
        _firstActionTaken.clear();
        lastActionPlayerIndex = null;
        _playbackIndex = 0;
        _updatePlaybackState();
        playerTypes.clear();
        for (int i = 0; i < _showActionHints.length; i++) {
          _showActionHints[i] = true;
        }
      });
    }
  }

  SavedHand _currentSavedHand() {
    return SavedHand(
      heroIndex: heroIndex,
      heroPosition: _heroPosition,
      numberOfPlayers: numberOfPlayers,
      playerCards: [
        for (int i = 0; i < numberOfPlayers; i++)
          List<CardModel>.from(playerCards[i])
      ],
      boardCards: List<CardModel>.from(boardCards),
      actions: List<ActionEntry>.from(actions),
      stackSizes: Map<int, int>.from(stackSizes),
      playerPositions: Map<int, String>.from(playerPositions),
      playerTypes: Map<int, String>.from(playerTypes),
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
    );
  }

  String saveHand() {
    final hand = _currentSavedHand();
    return jsonEncode(hand.toJson());
  }

  void loadHand(String jsonStr) {
    final hand = SavedHand.fromJson(jsonDecode(jsonStr));
    setState(() {
      heroIndex = hand.heroIndex;
      _heroPosition = hand.heroPosition;
      numberOfPlayers = hand.numberOfPlayers;
      for (int i = 0; i < playerCards.length; i++) {
        playerCards[i]
          ..clear()
          ..addAll(i < hand.playerCards.length ? hand.playerCards[i] : []);
      }
      boardCards
        ..clear()
        ..addAll(hand.boardCards);
      actions
        ..clear()
        ..addAll(hand.actions);
      stackSizes
        ..clear()
        ..addAll(hand.stackSizes);
      playerPositions
        ..clear()
        ..addAll(hand.playerPositions);
      playerTypes
        ..clear()
        ..addAll(hand.playerTypes ??
            {for (final k in hand.playerPositions.keys) k: 'standard'});
      _commentController.text = hand.comment ?? '';
      _recalculatePots();
      _recalculateStreetInvestments();
      currentStreet = 0;
      _playbackIndex = 0;
      _updatePlaybackState();
      _updatePositions();
    });
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _playbackTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildBetChipsOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final crowded = numberOfPlayers > 6;
    final scale = crowded ? (screenSize.height < 700 ? 0.8 : 0.9) : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final extraOffset = numberOfPlayers > 7 ? (numberOfPlayers - 7) * 15.0 : 0.0;
    final centerY = screenSize.height / 2 -
        (numberOfPlayers > 6 ? 160 + extraOffset : 120);
    final radiusX = (tableWidth / 2 - 60) * scale;
    final radiusY = (tableHeight / 2 + 90) * scale;

    final List<Widget> chips = [];
    for (int i = 0; i < numberOfPlayers; i++) {
      final index = (i + heroIndex) % numberOfPlayers;
      final playerActions = actions
          .where((a) => a.playerIndex == index && a.street == currentStreet)
          .toList();
      if (playerActions.isEmpty) continue;
      final lastAction = playerActions.last;
      if (['bet', 'raise', 'call'].contains(lastAction.action) &&
          lastAction.amount != null) {
        final angle = 2 * pi * (i - heroIndex) / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = _verticalBiasFromAngle(angle) * scale;
        chips.add(Positioned(
          left: centerX + dx - 10 * scale,
          top: centerY + dy + bias - 80 * scale,
          child: ChipWidget(
            amount: lastAction.amount!,
            scale: 0.8 * scale,
          ),
        ));
      }
    }
    return Stack(children: chips);
  }

  Widget _buildInvestedChipsOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final crowded = numberOfPlayers > 6;
    final scale = crowded ? (screenSize.height < 700 ? 0.8 : 0.9) : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final extraOffset = numberOfPlayers > 7 ? (numberOfPlayers - 7) * 15.0 : 0.0;
    final centerY =
        screenSize.height / 2 - (numberOfPlayers > 6 ? 160 + extraOffset : 120);
    final radiusX = (tableWidth / 2 - 60) * scale;
    final radiusY = (tableHeight / 2 + 90) * scale;

    final List<Widget> chips = [];
    for (int i = 0; i < numberOfPlayers; i++) {
      final index = (i + heroIndex) % numberOfPlayers;
      final invested = actions
          .where((a) =>
              a.playerIndex == index &&
              a.street == currentStreet &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise') &&
              a.amount != null)
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
      if (invested > 0) {
        final angle = 2 * pi * (i - heroIndex) / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = _verticalBiasFromAngle(angle) * scale;
        chips.add(Positioned(
          left: centerX + dx - 10 * scale,
          top: centerY + dy + bias - 110 * scale,
          child: ChipWidget(
            amount: invested,
            scale: 0.7 * scale,
          ),
        ));
      }
    }
    return Stack(children: chips);
  }

  Widget _buildStackDisplayOverlay() {
    final screenSize = MediaQuery.of(context).size;
    final crowded = numberOfPlayers > 6;
    final scale = crowded ? (screenSize.height < 700 ? 0.8 : 0.9) : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final extraOffset = numberOfPlayers > 7 ? (numberOfPlayers - 7) * 15.0 : 0.0;
    final centerY =
        screenSize.height / 2 - (numberOfPlayers > 6 ? 160 + extraOffset : 120);
    final radiusX = (tableWidth / 2 - 60) * scale;
    final radiusY = (tableHeight / 2 + 90) * scale;

    final List<Widget> chips = [];
    for (int i = 0; i < numberOfPlayers; i++) {
      final index = (i + heroIndex) % numberOfPlayers;
      final stack = stackSizes[index] ?? 0;
      if (stack > 0) {
        final angle = 2 * pi * (i - heroIndex) / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = _verticalBiasFromAngle(angle) * scale;
        chips.add(Positioned(
          left: centerX + dx - 10 * scale,
          top: centerY + dy + bias - 140 * scale,
          child: ChipWidget(
            amount: stack,
            scale: 0.6 * scale,
          ),
        ));
      }
    }
    return Stack(children: chips);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final visibleActions = actions.take(_playbackIndex).toList();
    final bool crowded = numberOfPlayers > 6;
    final double scale = crowded
        ? (screenSize.height < 700 ? 0.8 : 0.9)
        : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final extraOffset = numberOfPlayers > 7 ? (numberOfPlayers - 7) * 15.0 : 0.0;
    final centerY = screenSize.height / 2 -
        (numberOfPlayers > 6 ? 160 + extraOffset : 120);
    final radiusX = (tableWidth / 2 - 60) * scale;
    final radiusY = (tableHeight / 2 + 90) * scale;

    final effectiveStack = _calculateEffectiveStack(fromActions: visibleActions);
    final pot = _pots[currentStreet];
    final double? sprValue =
        pot > 0 ? effectiveStack / pot : null;

    ActionEntry? lastStreetAction;
    for (final a in visibleActions.reversed) {
      if (a.street == currentStreet) {
        lastStreetAction = a;
        break;
      }
    }
    final List<Widget> chipTrails = [];
    final List<Widget> playerWidgets = [];
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
          children: [
            DropdownButton<int>(
              value: numberOfPlayers,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: Colors.white,
              items: [
                for (int i = 2; i <= 9; i++)
                  DropdownMenuItem(value: i, child: Text('Игроков: $i')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    numberOfPlayers = value;
                    playerPositions = Map.fromIterables(
                      List.generate(numberOfPlayers, (i) => i),
                      getPositionList(numberOfPlayers),
                    );
                    for (int i = 0; i < numberOfPlayers; i++) {
                      playerTypes.putIfAbsent(i, () => 'standard');
                    }
                    playerTypes.removeWhere((key, _) => key >= numberOfPlayers);
                    _updatePositions();
                  });
                }
              },
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Stack(
                  children: [
                  Center(
                    child: Image.asset(
                      'assets/table.png',
                      width: tableWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                  BoardCardsWidget(scale: scale,
                    currentStreet: currentStreet,
                    boardCards: boardCards,
                    onCardSelected: selectBoardCard,
                  ),
                  // Pot display in the center of the table
                  if (pot > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CentralPotChips(
                                amount: pot,
                                scale: 1.3 * scale,
                              ),
                              SizedBox(height: 4 * scale),
                              CentralPotWidget(
                                text: 'Pot: ${_formatAmount(pot)}',
                                scale: scale,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  for (int i = 0; i < numberOfPlayers; i++) {
                    final index = (i + heroIndex) % numberOfPlayers;
                    final angle =
                        2 * pi * (i - heroIndex) / numberOfPlayers + pi / 2;
                    final dx = radiusX * cos(angle);
                    final dy = radiusY * sin(angle);
                    final bias = _verticalBiasFromAngle(angle) * scale;

                    final isFolded = visibleActions.any((a) =>
                        a.playerIndex == index &&
                        a.action == 'fold' &&
                        a.street <= currentStreet);
                    final actionTag = _actionTags[index];

                    ActionEntry? lastAction;
                    for (final a in visibleActions.reversed) {
                      if (a.playerIndex == index && a.street == currentStreet) {
                        lastAction = a;
                        break;
                      }
                    }

                    final invested =
                        _streetInvestments[currentStreet]?[index] ?? 0;

                    final Color? actionColor =
                        (lastAction?.action == 'bet' ||
                                lastAction?.action == 'raise')
                            ? Colors.green
                            : lastAction?.action == 'call'
                                ? Colors.blue
                                : null;
                    final double maxRadius = 36 * scale;
                    final double radius = (_pots[currentStreet] > 0)
                        ? min(
                            maxRadius,
                            (invested / _pots[currentStreet]) * maxRadius,
                          )
                        : 0.0;

                    final bool showTrail = invested > 0 &&
                        (lastAction != null &&
                            (lastAction!.action == 'bet' ||
                                lastAction!.action == 'raise' ||
                                lastAction!.action == 'call'));
                    if (showTrail) {
                      final fraction = _pots[currentStreet] > 0
                          ? invested / _pots[currentStreet]
                          : 0.0;
                      final trailCount = 3 + (fraction * 2).clamp(0, 2).round();
                      chipTrails.add(Positioned.fill(
                        child: ChipTrail(
                          start: Offset(centerX + dx, centerY + dy + bias + 92 * scale),
                          end: Offset(centerX, centerY),
                          chipCount: trailCount,
                          visible: showTrail,
                          scale: scale,
                          color: actionColor ?? Colors.green,
                        ),
                      ));
                      final tableChipCount =
                          (invested / 20).clamp(1, 5).round();
                      chipTrails.add(Positioned.fill(
                        child: BetChipsOnTable(
                          start: Offset(centerX + dx, centerY + dy + bias + 92 * scale),
                          end: Offset(centerX, centerY),
                          chipCount: tableChipCount,
                          color: lastAction!.action == 'call'
                              ? Colors.blue
                              : Colors.green,
                          scale: scale,
                        ),
                      ));
                    }

                    playerWidgets.addAll([
                      // action arrow behind player widgets
                      Positioned(
                        left: centerX + dx,
                        top: centerY + dy + bias + 12,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: (lastStreetAction != null &&
                                    lastStreetAction!.playerIndex == index &&
                                    (lastStreetAction!.action == 'bet' ||
                                        lastStreetAction!.action == 'raise' ||
                                        lastStreetAction!.action == 'call'))
                                ? 1.0
                                : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Transform.rotate(
                              angle: atan2(
                                  centerY - (centerY + dy + bias + 12),
                                  centerX - (centerX + dx)),
                              alignment: Alignment.topLeft,
                              child: Container(
                                width: sqrt(pow(centerX - (centerX + dx), 2) +
                                    pow(centerY - (centerY + dy + bias + 12), 2)),
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withOpacity(0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orangeAccent.withOpacity(0.6),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: centerX + dx - 55 * scale,
                        top: centerY + dy + bias - 55 * scale,
                      child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              activePlayerIndex = index;
                            });
                            final result = await showDetailedActionBottomSheet(
                              context,
                              potSizeBB: _pots[currentStreet],
                              stackSizeBB: stackSizes[index] ?? 0,
                              currentStreet: currentStreet,
                            );
                            if (result != null) {
                              final street = result['street'] as int? ?? currentStreet;
                              final entry = ActionEntry(
                                street,
                                index,
                                result['action'] as String,
                                amount: result['amount'] as int?,
                              );
                              final existingIndex = actions.lastIndexWhere((a) =>
                                  a.playerIndex == index && a.street == street);
                              setState(() {
                                if (existingIndex != -1) {
                                  _updateAction(existingIndex, entry);
                                } else {
                                  _addAction(entry);
                                }
                              });
                            }
                            setState(() {
                              if (activePlayerIndex == index) {
                                activePlayerIndex = null;
                              }
                            });
                          },
                          onDoubleTap: () {
                            setState(() {
                              heroIndex = index;
                              _updatePositions();
                            });
                          },
                          onLongPress: () => _selectPlayerType(index),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PlayerZoneWidget(
                                scale: scale,
                                playerName: 'Player ${index + 1}',
                                position: playerPositions[index],
                                cards: playerCards[index],
                                isHero: index == heroIndex,
                                isFolded: isFolded,
                                isActive: index == activePlayerIndex,
                                highlightLastAction:
                                    index == lastActionPlayerIndex,
                                showHint: _showActionHints[index],
                                actionTagText: actionTag,
                                onCardsSelected: (card) => selectCard(index, card),
                                stack: stackSizes[index] ?? 0,
                                onStackTap: () => _editStackSize(index),
                                  ),
                                  SizedBox(width: 4 * scale),
                                  Text(
                                    _playerTypeIcon(playerTypes[index]),
                                    style: TextStyle(fontSize: 18 * scale),
                                  ),
                                ],
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(opacity: animation, child: child),
                                ),
                                child: ChipWidget(
                                  key: ValueKey(stackSizes[index] ?? 0),
                                  amount: stackSizes[index] ?? 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (lastAction != null &&
                          (lastAction!.action == 'bet' ||
                              lastAction!.action == 'raise' ||
                              lastAction!.action == 'call') &&
                          lastAction!.amount != null)
                        Positioned(
                          left: centerX + dx - 35 * scale,
                          top: centerY + dy + bias + 85 * scale,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(scale: animation, child: child),
                            ),
                            child: Container(
                              key: ValueKey('${lastAction!.action}_${lastAction!.amount}'),
                              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
                              decoration: BoxDecoration(
                                color: _actionColor(lastAction!.action),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_actionIcon(lastAction!.action) != null) ...[
                                    Icon(
                                      _actionIcon(lastAction!.action),
                                      size: 14 * scale,
                                      color: _actionTextColor(lastAction!.action),
                                    ),
                                    SizedBox(width: 4 * scale),
                                  ],
                                  Text(
                                    _actionLabel(lastAction!),
                                    style: TextStyle(
                                      color: _actionTextColor(lastAction!.action),
                                      fontSize: 13 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (invested > 0) ...[
                        if (_pots[currentStreet] > 0 &&
                            (lastAction?.action == 'bet' ||
                                lastAction?.action == 'raise' ||
                                lastAction?.action == 'call'))
                          Positioned(
                            left: centerX + dx - radius,
                            top: centerY + dy + bias + 112 * scale - radius,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(scale: animation, child: child),
                              ),
                              child: AnimatedContainer(
                                key: ValueKey(radius),
                                duration: const Duration(milliseconds: 300),
                                width: radius * 2,
                                height: radius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: actionColor.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: centerX + dx - 20 * scale,
                          top: centerY + dy + bias + 92 * scale,
                          child: InvestedChipTokens(
                            amount: invested,
                            color: actionColor ?? Colors.green,
                            scale: scale,
                          ),
                        ),
                      ],
                      if (!isFolded && !((stackSizes[index] ?? 0) == 0 && invested == 0))
                        Positioned(
                          left: centerX + dx - 50 * scale,
                          top: centerY + dy + bias + 124 * scale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'S: ${_formatAmount(stackSizes[index] ?? 0)}   I: ${_formatAmount(invested)}',
                              style: TextStyle(color: Colors.white, fontSize: 11 * scale),
                            ),
                          ),
                        ),
                      if (debugLayout)
                        Positioned(
                          left: centerX + dx - 40 * scale,
                          top: centerY + dy + bias - 70 * scale,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            color: Colors.black45,
                            child: Text(
                              'a:${angle.toStringAsFixed(2)}\n${dx.toStringAsFixed(1)},${dy.toStringAsFixed(1)}',
                              style: TextStyle(
                                  color: Colors.yellow, fontSize: 9 * scale),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ]);
                  }
                    ...playerWidgets,
                    ...chipTrails,
                    _buildBetChipsOverlay(),
                    _buildInvestedChipsOverlay(),
                    _buildStackDisplayOverlay(),
                  Align(
                  alignment: Alignment.topRight,
                  child: HudOverlay(
                    streetName: ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'][currentStreet],
                    potText: _formatAmount(_pots[currentStreet]),
                    stackText: _formatAmount(effectiveStack),
                sprText: sprValue != null
                    ? 'SPR: ${sprValue.toStringAsFixed(1)}'
                    : null,
                  ),
                )
              ],
            ),
          ),
        ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: _stepBackward,
                  ),
                  IconButton(
                    icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white),
                    onPressed: _isPlaying ? _pausePlayback : _startPlayback,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: _stepForward,
                  ),
                  Expanded(
                    child: Slider(
                      value: _playbackIndex.toDouble(),
                      min: 0,
                      max: actions.isNotEmpty
                          ? actions.length.toDouble()
                          : 1,
                      onChanged: (v) {
                        _pausePlayback();
                        setState(() {
                          _playbackIndex = v.round();
                        });
                        _updatePlaybackState();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CollapsibleStreetSummary(
                      actions: actions,
                      playerPositions: playerPositions,
                      pots: _pots,
                      stackSizes: stackSizes,
                      onEdit: _editAction,
                      onDelete: _deleteAction,
                      visibleCount: _playbackIndex,
                      evaluateActionQuality: _evaluateActionQuality,
                    ),
                    StreetActionsWidget(
                      currentStreet: currentStreet,
                      onStreetChanged: (index) {
                        setState(() {
                          currentStreet = index;
                          _pots[currentStreet] =
                              _calculatePotForStreet(currentStreet);
                          _recalculateStreetInvestments();
                          _actionTags.clear();
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreetActionsList(
                        street: currentStreet,
                        actions: actions,
                        pots: _pots,
                        stackSizes: stackSizes,
                        onEdit: _editAction,
                        onDelete: _deleteAction,
                        visibleCount: _playbackIndex,
                        evaluateActionQuality: _evaluateActionQuality,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Комментарий к раздаче',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _resetHand,
                      child: const Text('Сбросить раздачу'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
