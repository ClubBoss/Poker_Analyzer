import 'package:flutter/material.dart';

/// Simple screen showing mock training spots.
class TrainingPacksScreen extends StatelessWidget {
  TrainingPacksScreen({super.key});

  final List<Map<String, dynamic>> _spots = [
    {
      'title': 'AA против KK',
      'description': 'Простой префлоп олл-ин',
      'data': {
        'heroIndex': 0,
        'numberOfPlayers': 2,
        'positions': ['BTN', 'BB'],
        'playerCards': [
          [
            {'rank': 'A', 'suit': 's'},
            {'rank': 'A', 'suit': 'd'}
          ],
          [
            {'rank': 'K', 'suit': 'h'},
            {'rank': 'K', 'suit': 'c'}
          ]
        ],
        'boardCards': [],
        'actions': [
          {'street': 0, 'playerIndex': 0, 'action': 'push', 'amount': 20},
          {'street': 0, 'playerIndex': 1, 'action': 'call', 'amount': 20},
        ],
      }
    },
    {
      'title': 'Флоп Q72',
      'description': 'C-бет в 3-бет поте',
      'data': {
        'heroIndex': 0,
        'numberOfPlayers': 2,
        'positions': ['BTN', 'BB'],
        'playerCards': [
          [
            {'rank': 'A', 'suit': 's'},
            {'rank': 'K', 'suit': 's'}
          ],
          [
            {'rank': 'Q', 'suit': 'h'},
            {'rank': 'Q', 'suit': 'd'}
          ]
        ],
        'boardCards': [
          {'rank': 'Q', 'suit': 's'},
          {'rank': '7', 'suit': 'h'},
          {'rank': '2', 'suit': 'd'}
        ],
        'actions': [
          {'street': 0, 'playerIndex': 0, 'action': 'raise', 'amount': 3},
          {'street': 0, 'playerIndex': 1, 'action': 'call', 'amount': 3},
          {'street': 1, 'playerIndex': 0, 'action': 'bet', 'amount': 5},
          {'street': 1, 'playerIndex': 1, 'action': 'fold'},
        ],
      }
    },
    {
      'title': 'Лимпованный банк',
      'description': 'Чек-рейз на флопе',
      'data': {
        'heroIndex': 1,
        'numberOfPlayers': 3,
        'positions': ['SB', 'BB', 'BTN'],
        'playerCards': [
          [
            {'rank': '7', 'suit': 'c'},
            {'rank': '8', 'suit': 'c'}
          ],
          [
            {'rank': '9', 'suit': 'd'},
            {'rank': '9', 'suit': 'h'}
          ],
          [
            {'rank': 'A', 'suit': 's'},
            {'rank': 'Q', 'suit': 's'}
          ]
        ],
        'boardCards': [
          {'rank': '7', 'suit': 'd'},
          {'rank': '4', 'suit': 'c'},
          {'rank': '2', 'suit': 'h'}
        ],
        'actions': [
          {'street': 1, 'playerIndex': 0, 'action': 'bet', 'amount': 2},
          {'street': 1, 'playerIndex': 1, 'action': 'raise', 'amount': 6},
        ],
      }
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные споты'),
      ),
      body: ListView.builder(
        itemCount: _spots.length,
        itemBuilder: (context, index) {
          final spot = _spots[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(spot['title'] as String),
              subtitle: Text(spot['description'] as String),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, spot['data']);
                },
                child: const Text('Загрузить'),
              ),
            ),
          );
        },
      ),
    );
  }
}
