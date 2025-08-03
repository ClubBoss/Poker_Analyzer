import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/user_preferences_service.dart';
import '../services/hand_history_file_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_template_service.dart';
import '../models/v2/training_pack_template.dart';
import '../helpers/pack_spot_utils.dart';
import 'training_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  List<TrainingPackTemplate> _templates = [];
  TrainingPackTemplate? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_templates.isEmpty) {
      _templates = TrainingPackTemplateService.getAllTemplates(context);
      if (_templates.isNotEmpty) _selected = _templates.first;
    }
  }

  Future<void> _finish() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool('tutorial_completed', true);
    await context.read<UserPreferencesService>().setTutorialCompleted(true);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _importHands() async {
    final manager = Provider.of<SavedHandManagerService>(context, listen: false);
    final service = await HandHistoryFileService.create(manager);
    await service.importFromFiles(context);
  }

  void _startStarterPack() {
    final tpl = _selected ??
        TrainingPackTemplateService.starterPushfold10bb(context);
    final hands = [for (final s in tpl.spots) handFromPackSpot(s, anteBb: tpl.anteBb)];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScreen.drill(
          hands: hands,
          templateId: tpl.id,
          templateName: tpl.name,
          minEvForCorrect: tpl.minEvForCorrect,
          anteBb: tpl.anteBb,
        ),
      ),
    );
  }

  Widget _page(String title, String text) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _page('Шаг 1', 'Импортируйте файлы Hand History для анализа'),
      _page('Шаг 2', 'Запустите базовый тренировочный пак'),
      _page('Шаг 3', 'Разберите сессии и изучите EV и ICM каждой раздачи'),
      _page('Шаг 4', 'Следите за ежедневными целями и достижениями'),
      _page('Шаг 5', 'Отслеживайте результаты в дашбордах прогресса'),
      _page('Шаг 6', 'Получайте персональные рекомендации для тренировок'),
      _page('Шаг 7', 'Подключите облачную синхронизацию для сохранения прогресса'),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _page('Готово', 'Вы готовы начать тренировку'),
          const SizedBox(height: 32),
          DropdownButton<TrainingPackTemplate>(
            dropdownColor: Colors.grey[850],
            value: _selected,
            items: [
              for (final t in _templates)
                DropdownMenuItem(
                  value: t,
                  child: Text(t.name,
                      style: const TextStyle(color: Colors.white)),
                )
            ],
            onChanged: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _importHands,
            child: const Text('Импортировать Hand History'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _startStarterPack,
            child: const Text('Стартовый пак'),
          ),
        ],
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Пропустить'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Шаг ${_index + 1} из ${pages.length}',
            style: const TextStyle(color: Colors.white70),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(
              value: (_index + 1) / pages.length,
              color: Colors.orange,
              backgroundColor: Colors.white24,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (v) => setState(() => _index = v),
              children: pages,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < pages.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? Colors.orange : Colors.white24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _index == pages.length - 1
                  ? _finish
                  : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
              child: Text(_index == pages.length - 1 ? 'Готово' : 'Далее'),
            ),
          ),
        ],
      ),
    );
  }
}
