import 'package:flutter/material.dart';

import '../models/v3/lesson_step.dart';
import '../services/lesson_loader_service.dart';
import 'lesson_step_screen.dart';

class LessonPathScreen extends StatefulWidget {
  const LessonPathScreen({super.key});

  @override
  State<LessonPathScreen> createState() => _LessonPathScreenState();
}

class _LessonPathScreenState extends State<LessonPathScreen> {
  late Future<List<LessonStep>> _future;

  @override
  void initState() {
    super.initState();
    _future = LessonLoaderService.instance.loadAllLessons();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LessonStep>>(
      future: _future,
      builder: (context, snapshot) {
        final steps = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Учебный путь')),
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : (steps == null || steps.isEmpty)
              ? const Center(
                  child: Text(
                    'Нет шагов',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    final intro = step.introText;
                    final preview = intro.length > 100
                        ? '${intro.substring(0, 100)}...'
                        : intro;
                    final statusIcon = index == 0
                        ? '🟢'
                        : (index % 3 == 1 ? '🟡' : '✅');
                    final buttonLabel = index == 0 ? 'Начать' : 'Продолжить';
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text('$statusIcon ${step.title}'),
                        subtitle: Text(
                          preview,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonStepScreen(step: step),
                              ),
                            );
                          },
                          child: Text(buttonLabel),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
