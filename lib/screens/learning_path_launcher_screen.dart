import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learning_path_horizontal_view_screen.dart';
import 'learning_path_linear_view_screen.dart';

enum LearningPathViewMode { horizontal, linear }

class LearningPathLauncherScreen extends StatefulWidget {
  const LearningPathLauncherScreen({super.key});

  @override
  State<LearningPathLauncherScreen> createState() =>
      _LearningPathLauncherScreenState();
}

class _LearningPathLauncherScreenState
    extends State<LearningPathLauncherScreen> {
  static const _prefsKey = 'learning_path_view_mode';
  LearningPathViewMode _mode = LearningPathViewMode.horizontal;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    setState(() {
      if (stored == 'linear') {
        _mode = LearningPathViewMode.linear;
      } else {
        _mode = LearningPathViewMode.horizontal;
      }
      _loading = false;
    });
  }

  Future<void> _setMode(LearningPathViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey,
        mode == LearningPathViewMode.linear ? 'linear' : 'horizontal');
    setState(() {
      _mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Path'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<LearningPathViewMode>(
              onSelected: _setMode,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: LearningPathViewMode.horizontal,
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_forward),
                      SizedBox(width: 8),
                      Text('Горизонтальный'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LearningPathViewMode.linear,
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_upward),
                      SizedBox(width: 8),
                      Text('Вертикальный'),
                    ],
                  ),
                ),
              ],
              child: Row(
                children: const [
                  Icon(Icons.swap_vert),
                  SizedBox(width: 4),
                  Text('Режим просмотра'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _mode == LearningPathViewMode.horizontal
          ? const LearningPathHorizontalViewScreen(showAppBar: false)
          : const LearningPathLinearViewScreen(showAppBar: false),
    );
  }
}
