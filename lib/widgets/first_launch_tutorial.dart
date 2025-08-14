import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class FirstLaunchTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  const FirstLaunchTutorial({super.key, required this.onComplete});

  @override
  State<FirstLaunchTutorial> createState() => _FirstLaunchTutorialState();
}

class _FirstLaunchTutorialState extends State<FirstLaunchTutorial> {
  final _steps = const [
    'Progress - track results',
    'Training Packs - practice spots',
    'Analyzer - review any hand',
  ];
  int _index = 0;

  Future<void> _next() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_step_$_index', true);
    if (_index == _steps.length - 1) {
      widget.onComplete();
      return;
    }
    setState(() => _index++);
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _steps.length; i++) {
      await prefs.setBool('intro_step_$i', true);
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _steps[_index],
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: const Text('Skip'),
                    ),
                    ElevatedButton(
                      onPressed: _next,
                      child:
                          Text(_index == _steps.length - 1 ? 'Got it' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showFirstLaunchTutorial(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  void close() => entry.remove();
  entry = OverlayEntry(
    builder: (_) => FirstLaunchTutorial(onComplete: close),
  );
  overlay.insert(entry);
}
