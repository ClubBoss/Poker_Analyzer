import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/spot_of_the_day_service.dart';
import '../widgets/board_cards_widget.dart';
import 'spot_of_the_day_history_screen.dart';
import 'spot_of_the_day_retry_screen.dart';
import '../widgets/poker_table_painter.dart';
import '../widgets/player_info_widget.dart';
import '../helpers/table_geometry_helper.dart';
import '../models/card_model.dart';
import '../widgets/sync_status_widget.dart';

class SpotOfTheDayScreen extends StatefulWidget {
  const SpotOfTheDayScreen({super.key});

  @override
  State<SpotOfTheDayScreen> createState() => _SpotOfTheDayScreenState();
}

class _SpotOfTheDayScreenState extends State<SpotOfTheDayScreen> {
  @override
  void initState() {
    super.initState();
    final service = context.read<SpotOfTheDayService>();
    service.ensureTodaySpot();
  }

  void _chooseAction(SpotOfTheDayService service) async {
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
      await service.saveResult(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SpotOfTheDayService>();
    final spot = service.spot;
    if (spot == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Спот дня'),
          centerTitle: true,
          actions: [
            SyncStatusIcon.of(context),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SpotOfTheDayHistoryScreen()),
                );
              },
            )
          ],
        ),
        body: const Center(child: Text('Нет данных')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Спот дня'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SpotOfTheDayHistoryScreen()),
              );
            },
          )
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = TableGeometryHelper.tableScale(spot.numberOfPlayers);
          final tableWidth = constraints.maxWidth * 0.9 * scale;
          final tableHeight = tableWidth * 0.55;
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2 - 40;

          final List<Widget> children = [
            Positioned(
              left: centerX - tableWidth / 2,
              top: centerY - tableHeight / 2,
              width: tableWidth,
              height: tableHeight,
              child: CustomPaint(
                painter: PokerTablePainter(),
              ),
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
                if (service.result != null || spot.recommendedAction != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Ваш ответ: ${service.result ?? '-'} • Реком.: ${spot.recommendedAction ?? '-'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                if (service.correct != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      service.correct! ? 'Верно' : 'Ошибка',
                      style: TextStyle(
                        color: service.correct! ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => _chooseAction(service),
                  child: Text(service.result == null
                      ? 'Ваше решение'
                      : 'Изменить ответ'),
                ),
                if (service.history.any((e) => e.correct == false))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SpotOfTheDayRetryScreen()),
                        );
                      },
                      child: const Text('Повторить ошибки'),
                    ),
                  ),
              ],
            )),
      ),
    );
  }
}
