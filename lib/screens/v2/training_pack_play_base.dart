library training_pack_play_base;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/recent_packs_service.dart';

import '../../models/v2/training_pack_template.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/training_pack_variant.dart';
import 'training_pack_play_core.dart';

export 'dart:async';
export 'dart:convert';
export 'dart:math';

export 'package:collection/collection.dart';
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:provider/provider.dart';
export 'package:poker_analyzer/l10n/app_localizations.dart';

export '../../models/training_spot.dart';
export '../../models/action_entry.dart';
export '../../models/card_model.dart';
export '../../models/player_model.dart';
export '../../services/evaluation_executor_service.dart';

export '../../helpers/hand_utils.dart';
export '../../helpers/hand_type_utils.dart';

export '../../models/v2/training_pack_template.dart';
export '../../models/v2/training_pack_spot.dart';
export '../../models/v2/training_pack_variant.dart';
export '../../widgets/spot_quiz_widget.dart';
export '../../widgets/common/explanation_text.dart';
export '../../widgets/dynamic_progress_row.dart';
export '../../theme/app_colors.dart';
export '../../services/streak_service.dart';
export '../../services/streak_tracker_service.dart';
export '../../services/notification_service.dart';
export '../../services/mistake_review_pack_service.dart';
export '../../services/mistake_categorization_engine.dart';
export '../../models/mistake.dart';
export '../../widgets/poker_table_view.dart';
export 'package:uuid/uuid.dart';
export '../../helpers/mistake_advice.dart';
export '../../services/learning_path_progress_service.dart';
export '../../services/learning_path_service.dart';
export '../../services/smart_review_service.dart';
export '../../services/tag_mastery_service.dart';
export '../../services/training_pack_template_builder.dart';
export '../../services/achievement_service.dart';
export '../../services/achievement_trigger_engine.dart';
export '../../services/training_session_service.dart';
export '../training_recommendation_screen.dart';
export '../../services/pack_dependency_map.dart';
export '../../services/pack_library_loader_service.dart';
export '../../services/smart_stage_unlock_engine.dart';
export '../../services/mistake_tag_classifier.dart';
export '../../services/mistake_tag_cluster_service.dart';
export '../../core/training/library/training_pack_library_v2.dart';
export '../../models/v2/training_pack_template_v2.dart';
export '../../services/training_session_launcher.dart';
export '../../services/pinned_learning_service.dart';

export 'training_pack_play_core.dart';

abstract class TrainingPackPlayBase extends StatefulWidget {
  final TrainingPackTemplate template;
  final TrainingPackTemplate original;
  final TrainingPackVariant? variant;
  final List<TrainingPackSpot>? spots;
  const TrainingPackPlayBase({
    super.key,
    required this.template,
    this.variant,
    this.spots,
    TrainingPackTemplate? original,
  }) : original = original ?? template;
}

abstract class TrainingPackPlayBaseState<T extends TrainingPackPlayBase>
    extends State<T>
    with TrainingPackPlayCore<T> {
  late List<TrainingPackSpot> _spots;
  Map<String, String> _results = {};
  int _index = 0;
  bool _loading = true;
  PlayOrder _order = PlayOrder.sequential;
  int _streetCount = 0;
  final Map<String, int> _handCounts = {};
  final Map<String, int> _handTotals = {};
  bool _summaryShown = false;
  bool _autoAdvance = false;
  SpotFeedback? _feedback;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    unawaited(RecentPacksService.instance.record(widget.template));
  }

  @override
  TrainingPackTemplate get template => widget.template;

  @override
  List<TrainingPackSpot> get spots => _spots;

  @override
  set spots(List<TrainingPackSpot> value) => _spots = value;

  @override
  Map<String, String> get results => _results;

  @override
  set results(Map<String, String> value) => _results = value;

  @override
  int get index => _index;

  @override
  set index(int value) => _index = value;

  @override
  bool get loading => _loading;

  @override
  set loading(bool value) => _loading = value;

  @override
  PlayOrder get order => _order;

  @override
  set order(PlayOrder value) => _order = value;

  @override
  int get streetCount => _streetCount;

  @override
  set streetCount(int value) => _streetCount = value;

  @override
  Map<String, int> get handCounts => _handCounts;

  @override
  Map<String, int> get handTotals => _handTotals;

  @override
  bool get summaryShown => _summaryShown;

  @override
  set summaryShown(bool value) => _summaryShown = value;

  @override
  bool get autoAdvance => _autoAdvance;

  @override
  set autoAdvance(bool value) => _autoAdvance = value;

  @override
  SpotFeedback? get feedback => _feedback;

  @override
  set feedback(SpotFeedback? value) => _feedback = value;

  @override
  Timer? get feedbackTimer => _feedbackTimer;

  @override
  set feedbackTimer(Timer? value) => _feedbackTimer = value;
}
