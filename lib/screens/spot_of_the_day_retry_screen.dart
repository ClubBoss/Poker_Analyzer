import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../models/spot_of_day_history_entry.dart';
import '../models/training_spot.dart';
import '../services/spot_of_the_day_service.dart';
import '../widgets/board_cards_widget.dart';
import '../widgets/player_info_widget.dart';
import '../widgets/poker_table_painter.dart';
import '../helpers/table_geometry_helper.dart';
import '../widgets/sync_status_widget.dart';

class SpotOfTheDayRetryScreen extends StatefulWidget {
  const SpotOfTheDayRetryScreen({super.key});

  @override
  State<SpotOfTheDayRetryScreen> createState() =>
      _SpotOfTheDayRetryScreenState();
}

class _SpotOfTheDayRetryScreenState extends State<SpotOfTheDayRetryScreen> {
  late Future<List<TrainingSpot>> _spotsFuture;
  List<SpotOfDayHistoryEntry> _mistakes = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final service = context.read<SpotOfTheDayService>();
    _mistakes = service.history.where((e) => e.correct == false).toList();
    _spotsFuture = service.loadAllSpots();
  }

  Future<void> _chooseAction(
      SpotOfTheDayService service, SpotOfDayHistoryEntry entry) async {
    const actions = ['fold', 'check', 'call', 'bet', 'raise'];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Ваше действие'),
        children: [
          for (final a in actions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, a),
              child: Text(a),
            ),
        ],
      ),
    );
    if (result != null) {
      await service.updateHistoryEntry(entry.date, result,
          recommendedAction: entry.recommendedAction);
      setState(() {
        _mistakes = service.history.where((e) => e.correct == false).toList();
        if (_mistakes.isEmpty) {
          Navigator.pop(context);
        } else {
          _currentIndex = _currentIndex % _mistakes.length;
        }
      });
    }
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _mistakes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SpotOfTheDayService>();
    if (_mistakes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Повтор ошибок'),
          centerTitle: true,
          actions: [SyncStatusIcon.of(context)],
        ),
        backgroundColor: const Color(0xFF121212),
        body: const Center(
          child: Text('Ошибок нет', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final entry = _mistakes[_currentIndex];
    return FutureBuilder<List<TrainingSpot>>(
      future: _spotsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final spots = snapshot.data!;
        if (entry.spotIndex >= spots.length) {
          return const Scaffold(
            body: Center(child: Text('Спот не найден')),
          );
        }
        final spot = spots[entry.spotIndex];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Повтор ошибок'),
            centerTitle: true,
            actions: [SyncStatusIcon.of(context)],
          ),
          backgroundColor: const Color(0xFF121212),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final scale =
                  TableGeometryHelper.tableScale(spot.numberOfPlayers);
              final tableWidth = constraints.maxWidth * 0.9 * scale;
              final tableHeight = tableWidth * 0.55;
              final centerX = constraints.maxWidth / 2;
              final centerY = constraints.maxHeight / 2 - 40;

              final children = <Widget>[
                Positioned(
                  left: centerX - tableWidth / 2,
                  top: centerY - tableHeight / 2,
                  width: tableWidth,
                  height: tableHeight,
                  child: CustomPaint(painter: PokerTablePainter()),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.1),
                    child: BoardCardsWidget(
                      currentStreet: 3,
                      boardCards: spot.boardCards,
                      onCardSelected: (_, __) {},
                      onCardLongPress: null,
                      usedCards: const {},
                      editingDisabled: true,
                    ),
                  ),
                ),
              ];

              for (int i = 0; i < spot.numberOfPlayers; i++) {
                final pos = TableGeometryHelper.positionForPlayer(
                    i, spot.numberOfPlayers, tableWidth, tableHeight);
                final offsetX = centerX + pos.dx - 55 * scale;
                final offsetY = centerY + pos.dy - 55 * scale;
                final cards = spot.playerCards.length > i
                    ? spot.playerCards[i]
                    : <CardModel>[];
                children.add(Positioned(
                  left: offsetX,
                  top: offsetY,
                  child: PlayerInfoWidget(
                    position: spot.positions[i],
                    stack: spot.stacks[i],
                    tag: '',
                    cards: cards,
                    lastAction: null,
                    isActive: false,
                    isFolded: false,
                    isHero: i == spot.heroIndex,
                    isOpponent: false,
                    revealCards: true,
                    playerTypeIcon: '',
                    playerTypeLabel: null,
                    positionLabel: null,
                    blindLabel: null,
                    showLastIndicator: false,
                    onTap: null,
                    onDoubleTap: null,
                    onLongPress: null,
                    onEdit: null,
                    onStackTap: null,
                    onRemove: null,
                    onTimeExpired: null,
                    onCardTap: null,
                    streetInvestment: 0,
                    currentBet: 0,
                    remainingStack: spot.stacks[i],
                    timersDisabled: true,
                    isBust: false,
                  ),
                ));
              }

              return Stack(children: children);
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.userAction != null ||
                      entry.recommendedAction != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Ваш ответ: ${entry.userAction ?? '-'} • Реком.: ${entry.recommendedAction ?? '-'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (entry.correct != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        entry.correct! ? 'Верно' : 'Ошибка',
                        style: TextStyle(
                          color: entry.correct! ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => _chooseAction(service, entry),
                    child: Text(entry.userAction == null
                        ? 'Ваше решение'
                        : 'Изменить ответ'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _next,
                    child: const Text('Следующий'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
