import 'package:flutter/material.dart';

class InputScreen extends StatelessWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая раздача'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Игроки и позиции',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                children: [
                  for (var pos in [
                    'UTG', 'MP', 'CO',
                    'BTN', 'SB', 'BB'
                  ])
                    DragTarget<String>(
                      builder: (context, candidateData, rejectedData) {
                        return Card(
                          color: Colors.grey.shade900,
                          child: Center(
                            child: Text(
                              pos,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                        );
                      },
                      onAccept: (data) {
                        // пока заглушка
                      },
                    )
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Карты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (var card in ['A♠', 'K♠', 'Q♠', 'J♠', 'T♠'])
                  Draggable<String>(
                    data: card,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(card),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(card),
                        ),
                      ),
                    ),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(card),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
\n## Future Improvements\nTo show a chain of action arrows without cluttering the interface, consider rendering semi-transparent arrows for past actions and fading them out over time or collapsing them into a small history panel.
