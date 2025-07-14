import 'package:flutter/material.dart';

class EmptyTrainingScreen extends StatelessWidget {
  const EmptyTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: const Center(
        child: Text('Нет доступных паков для тренировки'),
      ),
    );
  }
}
