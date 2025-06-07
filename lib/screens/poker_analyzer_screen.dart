import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/board_cards_widget.dart';
import '../widgets/action_dialog.dart';
import '../widgets/chip_widget.dart';
import '../widgets/street_actions_list.dart';
import '../widgets/collapsible_street_summary.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/chip_trail.dart';
import '../helpers/poker_position_helper.dart';

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
    _updatePositions();
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

  int _calculateCallAmount(int playerIndex) {
    final streetActions =
        actions.where((a) => a.street == currentStreet).toList();
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

  bool _streetHasBet() {
    return actions
        .where((a) => a.street == currentStreet)
        .any((a) => a.action == 'bet' || a.action == 'raise');
  }

  int _calculatePotForStreet(int street) {
    int pot = 0;
    for (int s = 0; s <= street; s++) {
      pot += actions
          .where((a) => a.street == s &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise'))
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
    }
    return pot;
  }

  void _recalculatePots() {
    int cumulative = 0;
    for (int s = 0; s < _pots.length; s++) {
      final streetAmount = actions
          .where((a) => a.street == s &&
              (a.action == 'call' || a.action == 'bet' || a.action == 'raise'))
          .fold<int>(0, (sum, a) => sum + (a.amount ?? 0));
      cumulative += streetAmount;
      _pots[s] = cumulative;
    }
  }

  void _recalculateStreetInvestments() {
    _streetInvestments.clear();
    for (final a in actions) {
      if (a.action == 'call' || a.action == 'bet' || a.action == 'raise') {
        final streetMap = _streetInvestments.putIfAbsent(a.street, () => {});
        streetMap[a.playerIndex] =
            (streetMap[a.playerIndex] ?? 0) + (a.amount ?? 0);
      }
      // Do not remove chip contributions on "fold" so that
      // folded players still display their invested amount
    }
  }

  int _calculateEffectiveStack() {
    int? minStack;
    for (final entry in stackSizes.entries) {
      final index = entry.key;
      final folded = actions.any((a) =>
          a.playerIndex == index && a.action == 'fold' && a.street <= currentStreet);
      if (folded) continue;
      final stack = entry.value;
      if (minStack == null || stack < minStack) {
        minStack = stack;
      }
    }
    return minStack ?? 0;
  }

  void _addAutoFolds(ActionEntry entry) {
    final street = entry.street;
    final playerIndex = entry.playerIndex;
    int insertPos = actions.length - 1; // position before the new entry
    for (int i = 0; i < numberOfPlayers; i++) {
      if (i == playerIndex) continue;
      if (i >= playerIndex) continue; // earlier in simple index order
      final hasActionThisStreet =
          actions.any((a) => a.playerIndex == i && a.street == street);
      if (hasActionThisStreet) continue;
      final foldedEarlier = actions.any((a) =>
          a.playerIndex == i && a.action == 'fold' && a.street < street);
      if (foldedEarlier) continue;
      final autoFold =
          ActionEntry(street, i, 'fold', generated: true);
      actions.insert(insertPos, autoFold);
      insertPos++;
      _actionTags[i] = 'fold';
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
    _addAutoFolds(entry);
    lastActionPlayerIndex = entry.playerIndex;
    _actionTags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
    _recalculatePots();
    _recalculateStreetInvestments();
  }

  void onActionSelected(ActionEntry entry) {
    setState(() {
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
  }

  Future<void> _editAction(int index) async {
    final action = actions[index];
    final result = await showDialog<ActionEntry>(
      context: context,
      builder: (context) => ActionDialog(
        playerIndex: action.playerIndex,
        street: action.street,
        position: playerPositions[action.playerIndex] ?? '',
        pot: _pots[action.street],
        stackSize: stackSizes[action.playerIndex] ?? 0,
        initialAction: action.action,
        initialAmount: action.amount,
      ),
    );
    if (result != null) {
      setState(() {
        _updateAction(index, result);
      });
    }
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
        for (int i = 0; i < _showActionHints.length; i++) {
          _showActionHints[i] = true;
        }
      });
    }
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
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

    final effectiveStack = _calculateEffectiveStack();
    final pot = _pots[currentStreet];
    final double? sprValue =
        pot > 0 ? effectiveStack / pot : null;

    ActionEntry? lastStreetAction;
    for (final a in actions.reversed) {
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
                  if (_pots[currentStreet] > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: ChipWidget(
                              key: ValueKey(_pots[currentStreet]),
                              amount: _pots[currentStreet],
                            ),
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

                    final isFolded = actions.any((a) =>
                        a.playerIndex == index &&
                        a.action == 'fold' &&
                        a.street <= currentStreet);
                    final actionTag = _actionTags[index];

                    ActionEntry? lastAction;
                    for (final a in actions.reversed) {
                      if (a.playerIndex == index && a.street == currentStreet) {
                        lastAction = a;
                        break;
                      }
                    }

                    final invested =
                        _streetInvestments[currentStreet]?[index] ?? 0;

                    final Color? actionColor =
                        lastAction?.action == 'bet'
                            ? const Color(0xFFFFA500)
                            : lastAction?.action == 'raise'
                                ? const Color(0xFFFF6347)
                                : lastAction?.action == 'call'
                                    ? const Color(0xFF00BFFF)
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
                          color: actionColor ?? Colors.orangeAccent,
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
                            final existingIndex = actions.lastIndexWhere((a) =>
                                a.playerIndex == index &&
                                a.street == currentStreet);
                            final result = await showDialog<ActionEntry>(
                              context: context,
                              builder: (context) => ActionDialog(
                                playerIndex: index,
                                street: currentStreet,
                                position: playerPositions[index] ?? '',
                                pot: _pots[currentStreet],
                                stackSize: stackSizes[index] ?? 0,
                                initialAction: existingIndex != -1
                                    ? actions[existingIndex].action
                                    : null,
                                initialAmount: existingIndex != -1
                                    ? actions[existingIndex].amount
                                    : (_streetHasBet()
                                        ? _calculateCallAmount(index)
                                        : null),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                if (existingIndex != -1) {
                                  _updateAction(existingIndex, result);
                                } else {
                                  _addAction(result);
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
                          onLongPress: () => _editStackSize(index),
                          child: Column(
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
                      if (lastAction != null)
                        Positioned(
                          left: centerX + dx - 30 * scale,
                          top: centerY + dy + bias + 60 * scale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${lastAction!.action}${lastAction!.amount != null ? ' ${lastAction!.amount}' : ''}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (lastAction != null &&
                          (lastAction!.action == 'bet' ||
                              lastAction!.action == 'raise' ||
                              lastAction!.action == 'call') &&
                          lastAction!.amount != null)
                        Positioned(
                          left: centerX + dx - 20 * scale,
                          top: centerY + dy + bias + 85 * scale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              '${lastAction!.amount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                            child: ChipWidget(
                              key: ValueKey(invested),
                              amount: invested,
                            ),
                          ),
                        ),
                      ],
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
                    ...chipTrails,
                    ...playerWidgets,
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CollapsibleStreetSummary(
                      actions: actions,
                      playerPositions: playerPositions,
                      onEdit: _editAction,
                      onDelete: _deleteAction,
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
                        onEdit: _editAction,
                        onDelete: _deleteAction,
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
