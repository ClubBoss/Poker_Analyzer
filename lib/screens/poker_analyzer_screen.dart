import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../widgets/player_zone_widget.dart';
import '../widgets/street_actions_widget.dart';
import '../widgets/board_cards_widget.dart';

import '../widgets/pot_over_board_widget.dart';
import '../widgets/detailed_action_bottom_sheet.dart';
import '../widgets/chip_widget.dart';
import '../widgets/player_info_widget.dart';
import '../widgets/street_actions_list.dart';
import '../widgets/collapsible_street_section.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/chip_trail.dart';
import '../widgets/bet_chips_on_table.dart';
import '../widgets/invested_chip_tokens.dart';
import '../widgets/central_pot_widget.dart';
import '../widgets/central_pot_chips.dart';
import '../widgets/pot_display_widget.dart';
import '../widgets/card_selector.dart';
import '../widgets/player_bet_indicator.dart';
import '../widgets/player_stack_chips.dart';
import '../widgets/bet_stack_chips.dart';
import '../widgets/chip_amount_widget.dart';
import '../helpers/poker_position_helper.dart';
import '../models/saved_hand.dart';
import '../models/player_model.dart';
import '../widgets/action_timeline_widget.dart';

class PokerAnalyzerScreen extends StatefulWidget {
  final SavedHand? initialHand;

  const PokerAnalyzerScreen({super.key, this.initialHand});

  @override
  State<PokerAnalyzerScreen> createState() => _PokerAnalyzerScreenState();
}

class _PokerAnalyzerScreenState extends State<PokerAnalyzerScreen>
    with TickerProviderStateMixin {
  List<SavedHand> savedHands = [];
  int heroIndex = 0;
  String _heroPosition = 'BTN';
  int numberOfPlayers = 6;
  final List<List<CardModel>> playerCards = List.generate(10, (_) => []);
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
    9: 100,
  };
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  Set<String> get allTags =>
      savedHands.expand((hand) => hand.tags).toSet();
  Set<String> tagFilters = {};
  final List<bool> _showActionHints = List.filled(10, true);
  final Set<int> _firstActionTaken = {};
  int? activePlayerIndex;
  int? lastActionPlayerIndex;
  Timer? _activeTimer;
  final Map<int, String?> _actionTags = {};
  Map<int, String> playerPositions = {};
  Map<int, PlayerType> playerTypes = {};

  bool debugLayout = false;
  final Set<int> _expandedHistoryStreets = {};
  final Set<int> _animatedPlayersPerStreet = {};


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

  String _positionLabelForIndex(int index) {
    final pos = playerPositions[index];
    if (pos == null) return '';
    if (pos.startsWith('UTG')) return 'UTG';
    if (pos == 'HJ' || pos == 'MP') return 'MP';
    return pos;
  }


  double _verticalBiasFromAngle(double angle) {
    return 90 + 20 * sin(angle);
  }

  double _tableScale() {
    final extraPlayers = max(0, numberOfPlayers - 6);
    return (1.0 - extraPlayers * 0.05).clamp(0.75, 1.0);
  }

  double _centerYOffset(double scale) {
    double base;
    if (numberOfPlayers > 6) {
      base = 200.0 + (numberOfPlayers - 6) * 10.0;
    } else {
      base = 140.0 - (6 - numberOfPlayers) * 10.0;
    }
    return base * scale;
  }

  double _radiusModifier() {
    return (1 + (6 - numberOfPlayers) * 0.05).clamp(0.8, 1.2);
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

  String _playerTypeIcon(PlayerType? type) {
    switch (type) {
      case PlayerType.shark:
        return '🦈';
      case PlayerType.fish:
        return '🐟';
      case PlayerType.nit:
        return '🧊';
      case PlayerType.maniac:
        return '🔥';
      case PlayerType.callingStation:
        return '📞';
      default:
        return '';
    }
  }

  String _playerTypeLabel(PlayerType? type) {
    switch (type) {
      case PlayerType.shark:
        return 'Shark';
      case PlayerType.fish:
        return 'Fish';
      case PlayerType.nit:
        return 'Nit';
      case PlayerType.maniac:
        return 'Maniac';
      case PlayerType.callingStation:
        return 'Calling Station';
      default:
        return 'Standard';
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

  void _addQualityTags() {
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet();
    bool misplay = false;
    bool aggressive = false;
    for (final a in actions) {
      final q = _evaluateActionQuality(a).toLowerCase();
      if (q.contains('плох') || q.contains('ошиб') || q.contains('bad')) {
        misplay = true;
      }
      if (q.contains('агресс') || q.contains('overbet') || q.contains('слишком')) {
        aggressive = true;
      }
    }
    if (misplay) tags.add('🚫 Мисс-плей');
    if (aggressive) tags.add('🤯 Слишком агрессивно');
    _tagsController.text = tags.join(', ');
  }

  Future<void> _selectPlayerType(int index) async {
    const types = [
      {'key': 'fish', 'icon': '🐟', 'label': 'Fish'},
      {'key': 'shark', 'icon': '🦈', 'label': 'Shark'},
      {'key': 'station', 'icon': '☎️', 'label': 'Calling Station'},
      {'key': 'maniac', 'icon': '🔥', 'label': 'Maniac'},
      {'key': 'nit', 'icon': '🧊', 'label': 'Nit'},
      {'key': 'standard', 'icon': '🔘', 'label': 'Standard'},
    ];
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in types)
              ListTile(
                leading: Text(t['icon']!, style: const TextStyle(fontSize: 24)),
                title: Text(t['label']!),
                onTap: () => Navigator.pop(context, t['key']),
              ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        playerTypes[index] =
            PlayerType.values.firstWhere((e) => e.name == result,
                orElse: () => PlayerType.unknown);
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

  Future<void> _editPlayerInfo(int index) async {
    final stackController =
        TextEditingController(text: (stackSizes[index] ?? 0).toString());
    PlayerType type = playerTypes[index] ?? PlayerType.unknown;
    bool isHeroSelected = index == heroIndex;
    CardModel? card1 =
        playerCards[index].isNotEmpty ? playerCards[index][0] : null;
    CardModel? card2 =
        playerCards[index].length > 1 ? playerCards[index][1] : null;

    const ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
    const suits = ['♠', '♥', '♦', '♣'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Edit Player', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: stackController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Stack',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type.name,
                    dropdownColor: Colors.grey[900],
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'standard', child: Text('standard')),
                      DropdownMenuItem(value: 'nit', child: Text('nit')),
                      DropdownMenuItem(value: 'fish', child: Text('fish')),
                      DropdownMenuItem(value: 'maniac', child: Text('maniac')),
                      DropdownMenuItem(value: 'shark', child: Text('shark')),
                      DropdownMenuItem(value: 'station', child: Text('station')),
                    ],
                    onChanged: (v) => setState(() =>
                        type = PlayerType.values.firstWhere(
                          (e) => e.name == v,
                          orElse: () => PlayerType.unknown,
                        )),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isHeroSelected,
                    title: const Text('Hero', style: TextStyle(color: Colors.white)),
                    onChanged: (v) => setState(() => isHeroSelected = v),
                    activeColor: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          DropdownButton<String>(
                            value: card1?.rank,
                            hint: const Text('Rank', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: ranks
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: (v) => setState(() => card1 = v != null && card1 != null
                                ? CardModel(rank: v, suit: card1!.suit)
                                : (v != null ? CardModel(rank: v, suit: suits.first) : null)),
                          ),
                          DropdownButton<String>(
                            value: card1?.suit,
                            hint: const Text('Suit', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: suits
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(() => card1 = v != null && card1 != null
                                ? CardModel(rank: card1!.rank, suit: v)
                                : (v != null ? CardModel(rank: ranks.first, suit: v) : null)),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          DropdownButton<String>(
                            value: card2?.rank,
                            hint: const Text('Rank', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: ranks
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: (v) => setState(() => card2 = v != null && card2 != null
                                ? CardModel(rank: v, suit: card2!.suit)
                                : (v != null ? CardModel(rank: v, suit: suits.first) : null)),
                          ),
                          DropdownButton<String>(
                            value: card2?.suit,
                            hint: const Text('Suit', style: TextStyle(color: Colors.white54)),
                            dropdownColor: Colors.grey[900],
                            items: suits
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(() => card2 = v != null && card2 != null
                                ? CardModel(rank: card2!.rank, suit: v)
                                : (v != null ? CardModel(rank: ranks.first, suit: v) : null)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      final int newStack =
          int.tryParse(stackController.text) ?? stackSizes[index] ?? 0;
      setState(() {
        stackSizes[index] = newStack;
        playerTypes[index] = type;
        if (isHeroSelected) {
          heroIndex = index;
        } else if (heroIndex == index) {
          heroIndex = 0;
        }
        final cards = <CardModel>[];
        if (card1 != null) cards.add(card1!);
        if (card2 != null) cards.add(card2!);
        playerCards[index] = cards;
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
      List.filled(numberOfPlayers, PlayerType.unknown),
    );
    _updatePositions();
    _updatePlaybackState();
    if (widget.initialHand != null) {
      _applySavedHand(widget.initialHand!);
    }
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

  Future<void> _onPlayerCardTap(int index, int cardIndex) async {
    final selectedCard = await showCardSelector(context);
    if (selectedCard == null) return;
    setState(() {
      for (final cards in playerCards) {
        cards.removeWhere((c) => c == selectedCard);
      }
      boardCards.removeWhere((c) => c == selectedCard);
      if (playerCards[index].length > cardIndex) {
        playerCards[index][cardIndex] = selectedCard;
      } else if (playerCards[index].length == cardIndex) {
        playerCards[index].add(selectedCard);
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
    if (_playbackIndex == 0) {
      _animatedPlayersPerStreet.clear();
    }
    _recalculatePots(fromActions: subset);
    _recalculateStreetInvestments(fromActions: subset);
    lastActionPlayerIndex =
        subset.isNotEmpty ? subset.last.playerIndex : null;
  }

  void _updateVisibleActions() {
    _updatePlaybackState();
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

  void _showStackInfo(int playerIndex) {
    final stack = stackSizes[playerIndex] ?? 0;
    const streetNames = ['Preflop', 'Flop', 'Turn', 'River'];
    final investments = [
      for (int i = 0; i < 4; i++)
        _streetInvestments[i]?[playerIndex] ?? 0
    ];
    final total = investments.fold<int>(0, (sum, v) => sum + v);
    final percent = stack > 0 ? (total / stack * 100) : 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          'Player ${playerIndex + 1} Stack',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stack: $stack',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < streetNames.length; i++)
              Text(
                '${streetNames[i]}: ${investments[i]}',
                style: const TextStyle(color: Colors.white70),
              ),
            const Divider(color: Colors.white24),
            Text(
              'Total invested: $total',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              '% of original stack: ${percent.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
          ],
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
      // Update action tag for player whose action was removed
      try {
        final last = actions.lastWhere((a) => a.playerIndex == removed.playerIndex);
        _actionTags[removed.playerIndex] =
            '${last.action}${last.amount != null ? ' ${last.amount}' : ''}';
      } catch (_) {
        _actionTags.remove(removed.playerIndex);
      }
      _updatePlaybackState();
    });
  }

  Future<void> _removeLastPlayerAction(int playerIndex) async {
    final actionIndex = actions.lastIndexWhere(
        (a) => a.playerIndex == playerIndex && a.street == currentStreet);
    if (actionIndex == -1) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить действие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _deleteAction(actionIndex);
    }
  }

  Future<void> _removePlayer(int index) async {
    if (numberOfPlayers <= 2) return;

    int updatedHeroIndex = heroIndex;

    if (index == heroIndex) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hero player is being removed'),
          content: const Text('What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'remove'),
              child: const Text('Remove anyway'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'change'),
              child: const Text('Change Hero'),
            ),
          ],
        ),
      );

      if (choice == null || choice == 'cancel') return;

      if (choice == 'change') {
        final selected = await showDialog<int>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select new hero'),
            children: [
              for (int i = 0; i < numberOfPlayers; i++)
                if (i != index)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, i),
                    child: Text('Player ${i + 1}'),
                  ),
            ],
          ),
        );
        if (selected == null) return;
        updatedHeroIndex = selected;
      }
    }

    setState(() {
      heroIndex = updatedHeroIndex;
      // Remove actions for this player and adjust indices
      actions.removeWhere((a) => a.playerIndex == index);
      for (int i = 0; i < actions.length; i++) {
        final a = actions[i];
        if (a.playerIndex > index) {
          actions[i] = ActionEntry(
            a.street,
            a.playerIndex - 1,
            a.action,
            amount: a.amount,
            generated: a.generated,
          );
        }
      }
      // Shift player-specific data
      for (int i = index; i < numberOfPlayers - 1; i++) {
        playerCards[i] = playerCards[i + 1];
        stackSizes[i] = stackSizes[i + 1] ?? 0;
        _actionTags[i] = _actionTags[i + 1];
        playerPositions[i] = playerPositions[i + 1] ?? '';
        playerTypes[i] = playerTypes[i + 1] ?? PlayerType.unknown;
        _showActionHints[i] = _showActionHints[i + 1];
      }
      playerCards[numberOfPlayers - 1] = [];
      stackSizes.remove(numberOfPlayers - 1);
      _actionTags.remove(numberOfPlayers - 1);
      playerPositions.remove(numberOfPlayers - 1);
      playerTypes.remove(numberOfPlayers - 1);
      _showActionHints[numberOfPlayers - 1] = true;

      if (heroIndex == index) {
        heroIndex = 0;
      } else if (heroIndex > index) {
        heroIndex--;
      }

      numberOfPlayers--;
      _updatePositions();
      _recalculatePots();
      _recalculateStreetInvestments();
      lastActionPlayerIndex = actions.isNotEmpty ? actions.last.playerIndex : null;
      if (_playbackIndex > actions.length) {
        _playbackIndex = actions.length;
      }
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
        _animatedPlayersPerStreet.clear();
        lastActionPlayerIndex = null;
        _playbackIndex = 0;
        _updatePlaybackState();
        playerTypes.clear();
        for (int i = 0; i < _showActionHints.length; i++) {
          _showActionHints[i] = true;
        }
        _commentController.clear();
        _tagsController.clear();
      });
    }
  }

  String _defaultHandName() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return 'Раздача от $day.$month.$year';
  }

  SavedHand _currentSavedHand({String? name}) {
    return SavedHand(
      name: name ?? _defaultHandName(),
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
      playerTypes: Map<int, PlayerType>.from(playerTypes),
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );
  }

  String saveHand() {
    _addQualityTags();
    final hand = _currentSavedHand();
    return jsonEncode(hand.toJson());
  }

  void loadHand(String jsonStr) {
    final hand = SavedHand.fromJson(jsonDecode(jsonStr));
    _applySavedHand(hand);
  }

  void _applySavedHand(SavedHand hand) {
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
            {for (final k in hand.playerPositions.keys) k: PlayerType.unknown});
      _commentController.text = hand.comment ?? '';
      _tagsController.text = hand.tags.join(', ');
      _recalculatePots();
      _recalculateStreetInvestments();
      currentStreet = 0;
      _playbackIndex = 0;
      _animatedPlayersPerStreet.clear();
      _updatePlaybackState();
      _updatePositions();
    });
  }

  Future<void> saveCurrentHand() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название раздачи'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Введите название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final handName = result.trim().isEmpty ? _defaultHandName() : result.trim();
    _addQualityTags();
    final hand = _currentSavedHand(name: handName);
    setState(() {
      savedHands.add(hand);
    });
  }

  void loadLastSavedHand() {
    if (savedHands.isEmpty) return;
    final hand = savedHands.last;
    _applySavedHand(hand);
  }

  Future<void> loadHandByName() async {
    if (savedHands.isEmpty) return;
    String filter = '';
    Set<String> localFilters = {...tagFilters};
    final selected = await showDialog<SavedHand>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final query = filter.toLowerCase();
          final filtered = [
            for (final hand in savedHands)
              if ((query.isEmpty ||
                      hand.tags.any((t) => t.toLowerCase().contains(query)) ||
                      hand.name.toLowerCase().contains(query) ||
                      (hand.comment?.toLowerCase().contains(query) ?? false)) &&
                  (localFilters.isEmpty ||
                      localFilters.every((tag) => hand.tags.contains(tag))))
                hand
          ];
          return AlertDialog(
            title: const Text('Выберите раздачу'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration:
                        const InputDecoration(hintText: 'Поиск'),
                    onChanged: (value) => setStateDialog(() => filter = value),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setStateSheet) {
                              final tags = allTags.toList()..sort();
                              if (tags.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Нет тегов'),
                                );
                              }
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  for (final tag in tags)
                                    CheckboxListTile(
                                      title: Text(tag),
                                      value: localFilters.contains(tag),
                                      onChanged: (checked) {
                                        setStateSheet(() {
                                          if (checked == true) {
                                            localFilters.add(tag);
                                          } else {
                                            localFilters.remove(tag);
                                          }
                                          tagFilters = Set.from(localFilters);
                                        });
                                        setStateDialog(() {});
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        );
                        setState(() {
                          tagFilters = Set.from(localFilters);
                        });
                        setStateDialog(() {});
                      },
                      child: const Text('Фильтр по тегам'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final hand = filtered[index];
                        final savedIndex = savedHands.indexOf(hand);
                        final title =
                            hand.name.isNotEmpty ? hand.name : 'Без названия';
                        return ListTile(
                          dense: true,
                          title: Text(
                            title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: () {
                            final items = <Widget>[];
                            if (hand.tags.isNotEmpty) {
                              items.add(Text(
                                hand.tags.join(', '),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ));
                            }
                            if (hand.comment?.isNotEmpty ?? false) {
                              items.add(Text(
                                hand.comment!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ));
                            }
                            return items.isEmpty
                                ? null
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: items,
                                  );
                          }(),
                          onTap: () => Navigator.pop(context, hand),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final nameController =
                              TextEditingController(text: hand.name);
                          final tagsController =
                              TextEditingController(text: hand.tags.join(', '));
                          final commentController =
                              TextEditingController(text: hand.comment ?? '');

                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                                left: 16,
                                right: 16,
                                top: 16,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                          labelText: 'Название'),
                                    ),
                                    const SizedBox(height: 8),
                                    Autocomplete<String>(
                                      optionsBuilder: (TextEditingValue value) {
                                        final input = value.text.toLowerCase();
                                        if (input.isEmpty) {
                                          return const Iterable<String>.empty();
                                        }
                                        return allTags.where((tag) =>
                                            tag.toLowerCase().contains(input));
                                      },
                                      displayStringForOption: (opt) => opt,
                                      onSelected: (selection) {
                                        final tags = tagsController.text
                                            .split(',')
                                            .map((t) => t.trim())
                                            .where((t) => t.isNotEmpty)
                                            .toSet();
                                        if (tags.add(selection)) {
                                          tagsController.text = tags.join(', ');
                                          tagsController.selection =
                                              TextSelection.fromPosition(
                                                  TextPosition(
                                                      offset: tagsController
                                                          .text.length));
                                        }
                                      },
                                      fieldViewBuilder: (context,
                                          textEditingController,
                                          focusNode,
                                          onFieldSubmitted) {
                                        textEditingController.text =
                                            tagsController.text;
                                        textEditingController.selection =
                                            tagsController.selection;
                                        textEditingController.addListener(() {
                                          if (tagsController.text !=
                                              textEditingController.text) {
                                            tagsController.value =
                                                textEditingController.value;
                                          }
                                        });
                                        tagsController.addListener(() {
                                          if (textEditingController.text !=
                                              tagsController.text) {
                                            textEditingController.value =
                                                tagsController.value;
                                          }
                                        });
                                        return TextField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                              labelText: 'Теги'),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: commentController,
                                      decoration: const InputDecoration(
                                          labelText: 'Комментарий'),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Отмена'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          final newName = nameController.text.trim();
                          final newTags = tagsController.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                          final newComment = commentController.text.trim();

                          final old = savedHands[savedIndex];
                          final oldName = old.name.trim();
                          final oldTags = old.tags
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                          final oldComment = old.comment?.trim() ?? '';

                          final hasChanges =
                              newName != oldName ||
                                  !listEquals(newTags, oldTags) ||
                                  newComment != oldComment;

                          if (hasChanges) {
                            setState(() {
                              savedHands[savedIndex] = SavedHand(
                                name: newName,
                                heroIndex: old.heroIndex,
                                heroPosition: old.heroPosition,
                                numberOfPlayers: old.numberOfPlayers,
                                playerCards: [
                                  for (final list in old.playerCards)
                                    List<CardModel>.from(list)
                                ],
                                boardCards: List<CardModel>.from(old.boardCards),
                                actions: List<ActionEntry>.from(old.actions),
                                stackSizes: Map<int, int>.from(old.stackSizes),
                                playerPositions:
                                    Map<int, String>.from(old.playerPositions),
                                playerTypes: old.playerTypes == null
                                    ? null
                                    : Map<int, String>.from(old.playerTypes!),
                                comment:
                                    newComment.isNotEmpty ? newComment : null,
                                tags: newTags,
                              );
                            });
                            setStateDialog(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Раздача обновлена')),
                            );
                          }

                          nameController.dispose();
                          tagsController.dispose();
                          commentController.dispose();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Удалить раздачу?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() {
                              savedHands.removeAt(savedIndex);
                            });
                            setStateDialog(() {});
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      _applySavedHand(selected);
    }
  }

  Future<void> exportLastSavedHand() async {
    if (savedHands.isEmpty) return;
    final jsonStr = jsonEncode(savedHands.last.toJson());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Раздача скопирована.')),
    );
  }

  Future<void> exportAllHands() async {
    if (savedHands.isEmpty) return;
    final jsonStr =
        jsonEncode([for (final hand in savedHands) hand.toJson()]);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${savedHands.length} hands exported to clipboard')),
    );
  }

  Future<void> importHandFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный формат данных.')),
      );
      return;
    }
    try {
      loadHand(data.text!);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный формат данных.')),
      );
    }
  }

  Future<void> importAllHandsFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data == null || data.text == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid data format')),
      );
      return;
    }

    try {
      final parsed = jsonDecode(data.text!);
      if (parsed is! List) throw const FormatException();

      int count = 0;
      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          try {
            savedHands.add(SavedHand.fromJson(item));
            count++;
          } catch (_) {
            // skip invalid hand objects
          }
        }
      }

      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count hands')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid data format')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid data format')),
      );
    }
  }



  @override
  void dispose() {
    _activeTimer?.cancel();
    _playbackTimer?.cancel();
    _commentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Widget _buildBetChipsOverlay(double scale) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

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
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
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

  Widget _buildInvestedChipsOverlay(double scale) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

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
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = _verticalBiasFromAngle(angle) * scale;

        final playerActions = actions
            .where((a) => a.playerIndex == index && a.street == currentStreet)
            .toList();
        final lastAction =
            playerActions.isNotEmpty ? playerActions.last : null;
        final color = _actionColor(lastAction?.action ?? 'bet');
        final start =
            Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset.lerp(start, Offset(centerX, centerY), 0.2)!;
        final animate = !_animatedPlayersPerStreet.contains(index);
        if (animate) {
          _animatedPlayersPerStreet.add(index);
        }
        chips.add(Positioned.fill(
          child: BetChipsOnTable(
            start: start,
            end: end,
            chipCount: (invested / 20).clamp(1, 5).round(),
            color: color,
            scale: scale,
            animate: animate,
          ),
        ));
      }
    }
    return Stack(children: chips);
  }

  Widget _buildBetStacksOverlay(double scale) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

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
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = _verticalBiasFromAngle(angle) * scale;

        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final pos = Offset.lerp(start, Offset(centerX, centerY), 0.15)!;

        final chipScale = scale * 0.8;
        chips.add(Positioned(
          left: pos.dx - 8 * chipScale,
          top: pos.dy - 8 * chipScale,
          child: BetStackChips(amount: invested, scale: chipScale),
        ));
      }
    }
    return Stack(children: chips);
  }

  Widget _buildPotAndBetsOverlay(double scale) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final List<Widget> items = [];

    final pot = _pots[currentStreet];
    if (pot > 0) {
      items.add(Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.05),
            child: Transform.translate(
              offset: Offset(0, -12 * scale),
              child: CentralPotChips(
                amount: pot,
                scale: scale,
              ),
            ),
          ),
        ),
      ));
      items.add(Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.25),
            child: PotDisplayWidget(
              amount: pot,
              scale: scale,
            ),
          ),
        ),
      ));
    }

    for (int i = 0; i < numberOfPlayers; i++) {
      final index = (i + heroIndex) % numberOfPlayers;
      final playerActions = actions
          .where((a) => a.playerIndex == index && a.street == currentStreet)
          .toList();
      if (playerActions.isEmpty) continue;
      final lastAction = playerActions.last;
      if (['bet', 'raise', 'call'].contains(lastAction.action) &&
          lastAction.amount != null) {
        final angle = 2 * pi * i / numberOfPlayers + pi / 2;
        final dx = radiusX * cos(angle);
        final dy = radiusY * sin(angle);
        final bias = _verticalBiasFromAngle(angle) * scale;
        final start = Offset(centerX + dx, centerY + dy + bias + 92 * scale);
        final end = Offset(centerX, centerY);
        final animate = !_animatedPlayersPerStreet.contains(index);
        if (animate) {
          _animatedPlayersPerStreet.add(index);
        }
        items.add(Positioned.fill(
          child: BetChipsOnTable(
            start: start,
            end: end,
            chipCount: (lastAction.amount! / 20).clamp(1, 5).round(),
            color: _actionColor(lastAction.action),
            scale: scale,
            animate: animate,
          ),
        ));
        items.add(Positioned(
          left: centerX + dx + 40 * scale,
          top: centerY + dy + bias - 40 * scale,
          child: PlayerBetIndicator(
            action: lastAction.action,
            amount: lastAction.amount!,
            scale: scale,
          ),
        ));
      }
    }

    return Stack(children: items);
  }

  Widget _buildActionHistoryOverlay() {
    final visible = actions.take(_playbackIndex).toList();
    final Map<int, List<ActionEntry>> grouped =
        {for (var i = 0; i < 4; i++) i: <ActionEntry>[]};
    for (final a in visible) {
      grouped[a.street]?.add(a);
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth < 350 ? 0.8 : 1.0;
    const streetNames = ['Префлоп', 'Флоп', 'Тёрн', 'Ривер'];

    Widget buildChip(ActionEntry a) {
      final pos = playerPositions[a.playerIndex] ?? 'P${a.playerIndex + 1}';
      final text = '$pos: ${a.action}${a.amount != null ? ' ${a.amount}' : ''}';
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: _actionColor(a.action).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _actionTextColor(a.action),
            fontSize: 11 * scale,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.black38,
        height: 70 * scale,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) {
            final list = grouped[index] ?? [];
            if (list.isEmpty) {
              return const SizedBox.shrink();
            }
            final expanded = _expandedHistoryStreets.contains(index);
            final visibleList = expanded || list.length <= 5
                ? list
                : list.sublist(list.length - 5);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedHistoryStreets.remove(index);
                  } else {
                    _expandedHistoryStreets.add(index);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streetNames[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * scale,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [for (final a in visibleList) buildChip(a)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final visibleActions = actions.take(_playbackIndex).toList();
    final double scale = _tableScale();
    final double infoScale = numberOfPlayers > 8 ? 0.85 : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final effectiveStack = _calculateEffectiveStack(fromActions: visibleActions);
    final pot = _pots[currentStreet];
    final double? sprValue =
        pot > 0 ? effectiveStack / pot : null;

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
                for (int i = 2; i <= 10; i++)
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
                    playerTypes.putIfAbsent(i, () => PlayerType.unknown);
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
                padding: const EdgeInsets.only(bottom: 8.0),
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
                  PotOverBoardWidget(
                    visibleActions: visibleActions,
                    currentStreet: currentStreet,
                    scale: scale,
                  ),
                  for (int i = 0; i < numberOfPlayers; i++) ..._buildPlayerWidgets(i, scale),
                  for (int i = 0; i < numberOfPlayers; i++) ..._buildChipTrail(i, scale),
                    _buildBetStacksOverlay(scale),
                    _buildInvestedChipsOverlay(scale),
                    _buildPotAndBetsOverlay(scale),
                    _buildActionHistoryOverlay(),
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
            StreetActionsWidget(
              currentStreet: currentStreet,
              onStreetChanged: (index) {
                setState(() {
                  currentStreet = index;
                  _pots[currentStreet] = _calculatePotForStreet(currentStreet);
                  _recalculateStreetInvestments();
                  _actionTags.clear();
                  _animatedPlayersPerStreet.clear();
                });
              },
            ),
            StreetActionInputWidget(
              currentStreet: currentStreet,
              numberOfPlayers: numberOfPlayers,
              actions: actions,
              playerPositions: playerPositions,
              onAdd: onActionSelected,
              onEdit: _editAction,
              onDelete: _deleteAction,
            ),
            ActionTimelineWidget(
              actions: visibleActions,
              playbackIndex: _playbackIndex,
              onTap: (index) {
                setState(() {
                  _playbackIndex = index;
                  _updateVisibleActions(); // Перестраиваем экран
                });
              },
              playerPositions: playerPositions,
              scale: scale,
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
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: () => saveCurrentHand(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open, color: Colors.white),
                    onPressed: loadLastSavedHand,
                  ),
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.white),
                    onPressed: () => loadHandByName(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    onPressed: exportLastSavedHand,
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_upload, color: Colors.white),
                    onPressed: exportAllHands,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: importHandFromClipboard,
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download, color: Colors.white),
                    onPressed: importAllHandsFromClipboard,
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
                    Column(
                      children: List.generate(4, (i) => CollapsibleStreetSection(
                        street: i,
                        actions: actions,
                        pots: _pots,
                        stackSizes: stackSizes,
                        playerPositions: playerPositions,
                        onEdit: _editAction,
                        onDelete: _deleteAction,
                        visibleCount: _playbackIndex,
                        evaluateActionQuality: _evaluateActionQuality,
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Комментарий к раздаче',
                          labelStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _tagsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Теги',
                          labelStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreetActionsList(
                        street: currentStreet,
                        actions: actions,
                        pots: _pots,
                        stackSizes: stackSizes,
                        playerPositions: playerPositions,
                        onEdit: _editAction,
                        onDelete: _deleteAction,
                        visibleCount: _playbackIndex,
                        evaluateActionQuality: _evaluateActionQuality,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {},
                      child: const Text('🔍 Проанализировать'),
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

  List<Widget> _buildPlayerWidgets(int i, double scale) {
    final screenSize = MediaQuery.of(context).size;
    final double infoScale = numberOfPlayers > 8 ? 0.85 : 1.0;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final visibleActions = actions.take(_playbackIndex).toList();

    ActionEntry? lastStreetAction;
    for (final a in visibleActions.reversed) {
      if (a.street == currentStreet) {
        lastStreetAction = a;
        break;
      }
    }

    final index = (i + heroIndex) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = _verticalBiasFromAngle(angle) * scale;

    final String position = playerPositions[index] ?? '';
    final int stack = stackSizes[index] ?? 0;
    final String tag = _actionTags[index] ?? '';
    final bool isActive = activePlayerIndex == index;
    final bool isFolded = visibleActions.any((a) =>
        a.playerIndex == index &&
        a.action == 'fold' &&
        a.street <= currentStreet);

    ActionEntry? lastAction;
    for (final a in visibleActions.reversed) {
      if (a.playerIndex == index && a.street == currentStreet) {
        lastAction = a;
        break;
      }
    }

    ActionEntry? lastAmountAction;
    for (final a in visibleActions.reversed) {
      if (a.playerIndex == index &&
          a.street == currentStreet &&
          (a.action == 'bet' ||
              a.action == 'raise' ||
              a.action == 'call') &&
          a.amount != null) {
        lastAmountAction = a;
        break;
      }
    }

    final invested = _streetInvestments[currentStreet]?[index] ?? 0;

    final Color? actionColor =
        (lastAction?.action == 'bet' || lastAction?.action == 'raise')
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

    final widgets = <Widget>[
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
        left: centerX + dx - 55 * scale * infoScale,
        top: centerY + dy + bias - 55 * scale * infoScale,
        child: Transform.scale(
          scale: infoScale,
          child: PlayerInfoWidget(
            position: position,
            stack: stack,
            tag: tag,
            cards: playerCards[index],
            lastAction: lastAction?.action,
            showLastIndicator: lastStreetAction?.playerIndex == index,
            isActive: isActive,
            isFolded: isFolded,
            isHero: index == heroIndex,
            playerTypeIcon: _playerTypeIcon(playerTypes[index]),
            playerTypeLabel:
                numberOfPlayers > 9 ? null : _playerTypeLabel(playerTypes[index]),
            positionLabel:
                numberOfPlayers <= 9 ? _positionLabelForIndex(index) : null,
            blindLabel: (playerPositions[index] == 'SB' ||
                    playerPositions[index] == 'BB')
                ? playerPositions[index]
                : null,
            onCardTap: (cardIndex) => _onPlayerCardTap(index, cardIndex),
            onTap: () => setState(() => activePlayerIndex = index),
            onDoubleTap: () => setState(() {
              heroIndex = index;
              _updatePositions();
            }),
            onLongPress: () => _editPlayerInfo(index),
            onEdit: () => _editPlayerInfo(index),
            onStackTap: (value) => setState(() {
              stackSizes[index] = value;
            }),
            onRemove: numberOfPlayers > 2 ? () {
              _removePlayer(index);
            } : null,
          ),
        ),
      ),
      if (lastAmountAction != null)
        Positioned(
          left: centerX + dx - 24 * scale,
          top: centerY + dy + bias - 80 * scale,
          child: ChipAmountWidget(
            amount: lastAmountAction!.amount!.toDouble(),
            color: _actionColor(lastAmountAction!.action),
            scale: scale,
          ),
        ),
      Positioned(
        left: centerX + dx - 12 * scale,
        top: centerY + dy + bias + 70 * scale,
        child: PlayerStackChips(
          stack: stack,
          scale: scale * 0.9,
        ),
      ),
      if (lastAction != null)
        Positioned(
          left: centerX + dx + 40 * scale,
          top: centerY + dy + bias - 60 * scale,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16 * scale,
            onPressed: () => _removeLastPlayerAction(index),
            icon: const Text('❌', style: TextStyle(color: Colors.redAccent)),
          ),
        ),
    ];

    if (invested > 0) {
      if (_pots[currentStreet] > 0 &&
          (lastAction?.action == 'bet' ||
              lastAction?.action == 'raise' ||
              lastAction?.action == 'call')) {
        widgets.add(Positioned(
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
                color: actionColor!.withOpacity(0.2),
              ),
            ),
          ),
        ));
      }
      widgets.add(Positioned(
        left: centerX + dx - 20 * scale,
        top: centerY + dy + bias + 92 * scale,
        child: InvestedChipTokens(
          amount: invested,
          color: actionColor ?? Colors.green,
          scale: scale,
        ),
      ));
    }

    if (debugLayout) {
      widgets.add(Positioned(
        left: centerX + dx - 40 * scale,
        top: centerY + dy + bias - 70 * scale,
        child: Container(
          padding: const EdgeInsets.all(2),
          color: Colors.black45,
          child: Text(
            'a:${angle.toStringAsFixed(2)}\n${dx.toStringAsFixed(1)},${dy.toStringAsFixed(1)}',
            style: TextStyle(color: Colors.yellow, fontSize: 9 * scale),
            textAlign: TextAlign.center,
          ),
        ),
      ));
    }

    return widgets;
  }

  List<Widget> _buildChipTrail(int i, double scale) {
    final screenSize = MediaQuery.of(context).size;
    final tableWidth = screenSize.width * 0.9;
    final tableHeight = tableWidth * 0.55;
    final centerX = screenSize.width / 2 + 10;
    final centerY = screenSize.height / 2 - _centerYOffset(scale);
    final radiusMod = _radiusModifier();
    final radiusX = (tableWidth / 2 - 60) * scale * radiusMod;
    final radiusY = (tableHeight / 2 + 90) * scale * radiusMod;

    final visibleActions = actions.take(_playbackIndex).toList();

    final index = (i + heroIndex) % numberOfPlayers;
    final angle = 2 * pi * i / numberOfPlayers + pi / 2;
    final dx = radiusX * cos(angle);
    final dy = radiusY * sin(angle);
    final bias = _verticalBiasFromAngle(angle) * scale;

    ActionEntry? lastAction;
    for (final a in visibleActions.reversed) {
      if (a.playerIndex == index && a.street == currentStreet) {
        lastAction = a;
        break;
      }
    }

    final invested = _streetInvestments[currentStreet]?[index] ?? 0;

    final Color? actionColor =
        (lastAction?.action == 'bet' || lastAction?.action == 'raise')
            ? Colors.green
            : lastAction?.action == 'call'
                ? Colors.blue
                : null;

    final bool showTrail = invested > 0 &&
        (lastAction != null &&
            (lastAction!.action == 'bet' ||
                lastAction!.action == 'raise' ||
                lastAction!.action == 'call'));

    if (!showTrail) return [];

    final fraction = _pots[currentStreet] > 0
        ? invested / _pots[currentStreet]
        : 0.0;
    final trailCount = 3 + (fraction * 2).clamp(0, 2).round();

    return [
      Positioned.fill(
        child: ChipTrail(
          start: Offset(centerX + dx, centerY + dy + bias + 92 * scale),
          end: Offset(centerX, centerY),
          chipCount: trailCount,
          visible: showTrail,
          scale: scale,
          color: actionColor ?? Colors.green,
        ),
      )
    ];
  }
}

class StreetActionInputWidget extends StatefulWidget {
  final int currentStreet;
  final int numberOfPlayers;
  final List<ActionEntry> actions;
  final Map<int, String> playerPositions;
  final void Function(ActionEntry) onAdd;
  final void Function(int, ActionEntry) onEdit;
  final void Function(int) onDelete;

  const StreetActionInputWidget({
    super.key,
    required this.currentStreet,
    required this.numberOfPlayers,
    required this.actions,
    required this.playerPositions,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<StreetActionInputWidget> createState() => _StreetActionInputWidgetState();
}

class _StreetActionInputWidgetState extends State<StreetActionInputWidget> {
  int _player = 0;
  String _action = 'fold';
  final TextEditingController _controller = TextEditingController();

  bool get _needAmount =>
      _action == 'bet' || _action == 'raise' || _action == 'call';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final amount = _needAmount ? int.tryParse(_controller.text) : null;
    widget.onAdd(ActionEntry(widget.currentStreet, _player, _action,
        amount: amount));
    _controller.clear();
  }

  void _editDialog(int index, ActionEntry entry) {
    int p = entry.playerIndex;
    String act = entry.action;
    final c = TextEditingController(
        text: entry.amount != null ? entry.amount.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool need = act == 'bet' || act == 'raise' || act == 'call';
          return AlertDialog(
            title: const Text('Редактировать действие'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: p,
                  items: [
                    for (int i = 0; i < widget.numberOfPlayers; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(widget.playerPositions[i] ??
                            'Player ${i + 1}'),
                      )
                  ],
                  onChanged: (v) => setState(() => p = v ?? p),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: act,
                  items: const [
                    DropdownMenuItem(value: 'fold', child: Text('fold')),
                    DropdownMenuItem(value: 'check', child: Text('check')),
                    DropdownMenuItem(value: 'call', child: Text('call')),
                    DropdownMenuItem(value: 'bet', child: Text('bet')),
                    DropdownMenuItem(value: 'raise', child: Text('raise')),
                  ],
                  onChanged: (v) => setState(() => act = v ?? act),
                ),
                if (need)
                  TextField(
                    controller: c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  final amt =
                      (act == 'bet' || act == 'raise' || act == 'call')
                          ? int.tryParse(c.text)
                          : null;
                  widget.onEdit(index,
                      ActionEntry(widget.currentStreet, p, act, amount: amt));
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streetActions = widget.actions
        .where((a) => a.street == widget.currentStreet)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownButton<int>(
              value: _player,
              items: [
                for (int i = 0; i < widget.numberOfPlayers; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(widget.playerPositions[i] ??
                        'Player ${i + 1}'),
                  )
              ],
              onChanged: (v) => setState(() => _player = v ?? _player),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _action,
              items: const [
                DropdownMenuItem(value: 'fold', child: Text('fold')),
                DropdownMenuItem(value: 'check', child: Text('check')),
                DropdownMenuItem(value: 'call', child: Text('call')),
                DropdownMenuItem(value: 'bet', child: Text('bet')),
                DropdownMenuItem(value: 'raise', child: Text('raise')),
              ],
              onChanged: (v) => setState(() => _action = v ?? _action),
            ),
            const SizedBox(width: 8),
            if (_needAmount)
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _add,
              child: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final a in streetActions)
          ListTile(
            dense: true,
            title: Text(
              '${widget.playerPositions[a.playerIndex] ?? 'Player ${a.playerIndex + 1}'} '
              '— ${a.action}${a.amount != null ? ' ${a.amount}' : ''}',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.amber),
                  onPressed: () =>
                      _editDialog(widget.actions.indexOf(a), a),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      widget.onDelete(widget.actions.indexOf(a)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
