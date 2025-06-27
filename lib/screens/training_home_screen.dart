import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/spot_of_the_day_service.dart';
import '../widgets/spot_of_the_day_card.dart';
import '../widgets/streak_chart.dart';
import '../widgets/daily_progress_ring.dart';
import '../widgets/repeat_mistakes_card.dart';
import '../widgets/weekly_challenge_card.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/quick_continue_card.dart';
import '../widgets/progress_summary_box.dart';
import 'training_progress_analytics_screen.dart';
import 'template_library_screen.dart';

class TrainingHomeScreen extends StatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  State<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SpotOfTheDayService>().ensureTodaySpot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TrainingProgressAnalyticsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: const [
          QuickContinueCard(),
          SpotOfTheDayCard(),
          ProgressSummaryBox(),
          StreakChart(),
          DailyProgressRing(),
          WeeklyChallengeCard(),
          XPProgressBar(),
          RepeatMistakesCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TemplateLibraryScreen()),
          );
        },
        child: const Icon(Icons.auto_awesome_motion),
      ),
    );
  }
}
