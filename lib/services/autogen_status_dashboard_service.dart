import 'package:flutter/foundation.dart';

import '../models/autogen_status.dart';

class AutogenStatusDashboardService {
  AutogenStatusDashboardService._();

  static final AutogenStatusDashboardService _instance =
      AutogenStatusDashboardService._();

  factory AutogenStatusDashboardService() => _instance;
  static AutogenStatusDashboardService get instance => _instance;

  final Map<String, AutogenStatus> _statuses = {};
  final ValueNotifier<Map<String, AutogenStatus>> notifier =
      ValueNotifier(const <String, AutogenStatus>{});

  void update(String module, AutogenStatus status) {
    _statuses[module] = status;
    notifier.value = Map.unmodifiable(_statuses);
  }

  AutogenStatus? getStatus(String module) => _statuses[module];

  Map<String, AutogenStatus> getAll() => Map.unmodifiable(_statuses);
}
