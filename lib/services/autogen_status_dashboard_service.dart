import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/autogen_status.dart';

class AutogenStatusDashboardService {
  AutogenStatusDashboardService._() {
    _loadLastRun();
  }

  static final AutogenStatusDashboardService _instance =
      AutogenStatusDashboardService._();

  factory AutogenStatusDashboardService() => _instance;
  static AutogenStatusDashboardService get instance => _instance;

  final ValueNotifier<AutogenStatus> notifier =
      ValueNotifier(const AutogenStatus());

  AutogenStatus get current => notifier.value;

  void updateStatus(AutogenStatus newStatus) {
    notifier.value = newStatus;
  }

  void start({String? templateSet}) {
    updateStatus(current.copyWith(
      status: AutogenPipelineStatus.running,
      activeStage: 'start',
      error: null,
      lastTemplateSet: templateSet ?? current.lastTemplateSet,
    ));
  }

  void stage(String stage, {String? templateSet}) {
    updateStatus(current.copyWith(
      activeStage: stage,
      lastTemplateSet: templateSet ?? current.lastTemplateSet,
    ));
  }

  Future<void> fail(String error) async {
    final now = DateTime.now();
    updateStatus(current.copyWith(
      status: AutogenPipelineStatus.failed,
      error: error,
      activeStage: null,
      lastRun: now,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRunKey, now.toIso8601String());
  }

  Future<void> complete() async {
    final now = DateTime.now();
    updateStatus(current.copyWith(
      status: AutogenPipelineStatus.completed,
      error: null,
      activeStage: null,
      lastRun: now,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRunKey, now.toIso8601String());
  }

  static const _lastRunKey = 'autogen_last_run';

  Future<void> _loadLastRun() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastRunKey);
    if (last != null) {
      final dt = DateTime.tryParse(last);
      if (dt != null) {
        updateStatus(current.copyWith(lastRun: dt));
      }
    }
  }
}
