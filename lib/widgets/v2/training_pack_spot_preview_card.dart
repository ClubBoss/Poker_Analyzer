import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/hero_position.dart';
import '../../models/action_entry.dart';
import '../../screens/v2/hand_editor_screen.dart';
import '../../services/evaluation_executor_service.dart';
import '../../theme/app_colors.dart';

/// ***Only the new Stateful implementation below is kept.
///   The former Stateless version has been removed to avoid a duplicate-class error.***

class TrainingPackSpotPreviewCard extends StatefulWidget {
  final TrainingPackSpot spot;
  final VoidCallback? onHandEdited;
  final ValueChanged<String>? onTagTap;
  final VoidCallback? onDuplicate;
  final VoidCallback? onNewTap;
  final VoidCallback? onDupTap;
  final bool showDuplicate;
  final Color? titleColor;
  final bool isMistake;
  final bool editableTitle;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onPersist;
  final TrainingPackTemplate? template;
  final Future<void> Function()? persist;
  final void Function(String id)? focusSpot;
  const TrainingPackSpotPreviewCard({
    super.key,
    required this.spot,
    this.onHandEdited,
    this.onTagTap,
    this.onDuplicate,
    this.onNewTap,
    this.onDupTap,
    this.titleColor,
    this.isMistake = false,
    this.showDuplicate = false,
    this.editableTitle = false,
    this.onTitleChanged,
    this.onPersist,
    this.template,
    this.persist,
    this.focusSpot,
  });
  @override
  State<TrainingPackSpotPreviewCard> createState() =>
      _TrainingPackSpotPreviewCardState();
}

class _TrainingPackSpotPreviewCardState
    extends State<TrainingPackSpotPreviewCard> {
  late final TextEditingController _titleCtr;
  final FocusNode _titleFocus = FocusNode();
  bool _editing = false;

  Color _priorityColor(int p) {
    switch (p) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.green;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _duplicate() {
    final tpl = widget.template;
    final persist = widget.persist;
    final focus = widget.focusSpot;
    if (tpl == null || persist == null || focus == null) {
      widget.onDuplicate?.call();
      return;
    }
    final i = tpl.spots.indexOf(widget.spot);
    if (i == -1) return;
    final copy = widget.spot.copyWith(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
    );
    tpl.spots.insert(i + 1, copy);
    persist();
    focus(copy.id);
  }

  @override
  void initState() {
    super.initState();
    _titleCtr = TextEditingController(text: widget.spot.title);
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus && _editing) _save();
    });
  }

  @override
  void didUpdateWidget(covariant TrainingPackSpotPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.spot.title != widget.spot.title) {
      _titleCtr.text = widget.spot.title;
    }
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _startEdit() {
    if (!widget.editableTitle) return;
    setState(() => _editing = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _titleFocus.requestFocus());
  }

  void _save() {
    final t = _titleCtr.text.trim();
    setState(() {
      widget.spot.title = t;
      _editing = false;
    });
    widget.onTitleChanged?.call(t);
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final hero = spot.hand.heroCards;
    final pos = spot.hand.position;
    final h = spot.hand.heroIndex;
    final pre = spot.hand.actions[0] ?? [];

    ActionEntry? heroAct;
    for (final a in pre) {
      if (a.playerIndex == h) {
        heroAct = a;
        break;
      }
    }
    final double? heroEv = spot.heroEv;
    final double? heroIcmEv = spot.heroIcmEv;
    final borderColor = heroEv == null
        ? Colors.grey
        : (heroEv.abs() <= 0.01
            ? Colors.grey
            : (heroEv > 0 ? Colors.green : Colors.red));
    final badgeColor = borderColor;
    final badgeText = heroEv == null
        ? ''
        : '${heroEv > 0 ? '+' : ''}${heroEv.toStringAsFixed(1)}';
    final icmBadgeText = heroIcmEv == null
        ? ''
        : '${heroIcmEv > 0 ? '+' : ''}${heroIcmEv.toStringAsFixed(3)}';

    final String? heroLabel = heroAct == null
        ? null
        : (heroAct.customLabel?.isNotEmpty == true
            ? heroAct.customLabel!
            : '${heroAct.action}${heroAct.amount != null && heroAct.amount! > 0 ? ' ${heroAct.amount!.toStringAsFixed(1)} BB' : ''}');
    final legacy = hero.isEmpty && spot.note.trim().isNotEmpty;
    final actions = spot.hand.actions;
    final board = [
      for (final street in [1, 2, 3])
        for (final a in actions[street] ?? [])
          if (a.action == 'board' && a.customLabel?.isNotEmpty == true)
            ...a.customLabel!.split(' ')
    ];
    final actionCount = actions.values
        .expand((e) => e)
        .where((a) => a.action != 'board' && !a.generated)
        .length;
    Color? barColor;
    if (heroEv != null) {
      if (heroEv > 0.5) {
        barColor = Colors.green;
      } else if (heroEv < -0.5) {
        barColor = Colors.red;
      } else {
        barColor = Colors.yellow;
      }
    }
    final needsWarning =
        spot.heroEv == null || spot.heroIcmEv == null;
    final recent = DateTime.now().difference(spot.editedAt) <
        const Duration(minutes: 5);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // removed outdated marker
          if (widget.isMistake)
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          if (barColor != null)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _editing
                            ? TextField(
                                controller: _titleCtr,
                                focusNode: _titleFocus,
                                decoration: const InputDecoration(
                                    isDense: true, border: InputBorder.none),
                                onSubmitted: (_) => _save(),
                              )
                            : GestureDetector(
                                onTap: _startEdit,
                                onDoubleTap: _startEdit,
                                child: Text(
                                  widget.spot.title.isEmpty
                                      ? 'Untitled spot'
                                      : widget.spot.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.titleColor,
                                  ),
                                ),
                              ),
                      ),
                      if (spot.isNew)
                        Tooltip(
                          message: 'New',
                          child: InkWell(
                            onTap: widget.onNewTap,
                            child: const Icon(Icons.fiber_new,
                                color: AppColors.accent),
                          ),
                        ),
                      if (widget.showDuplicate)
                        Tooltip(
                          message: 'Duplicate',
                          child: InkWell(
                            onTap: widget.onDupTap,
                            child: const Icon(Icons.copy_all,
                                color: Colors.redAccent),
                          ),
                        ),
                      if (spot.hand.playerCount > 2)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${spot.hand.playerCount}-handed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (heroEv != null) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              key: const ValueKey('evBadge'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (heroIcmEv != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                key: const ValueKey('icmBadge'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  icmBadgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                    ],
                  ],
                ),
                if (spot.evalResult?.correct == false &&
                    (spot.evalResult?.hint?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      spot.evalResult!.hint!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                if (hero.isNotEmpty || pos != HeroPosition.unknown || legacy)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      legacy ? '(legacy)' : '$hero ${pos.label}'.trim(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  if (heroLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        heroLabel.length > 40
                            ? heroLabel.substring(0, 40)
                            : heroLabel,
                        style: const TextStyle(
                            fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ),
                  if (board.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        children: [for (final c in board) Text(c)],
                      ),
                    ),
                  if (heroEv != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        heroEv >= 0
                            ? '+${heroEv.toStringAsFixed(2)} BB EV'
                            : '${heroEv.toStringAsFixed(2)} BB EV',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: heroEv >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                  if (spot.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (final tag in spot.tags)
                            InputChip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: () =>
                                  widget.onTagTap?.call(tag.toLowerCase()),
                            ),
                        ],
                      ),
                    ),
                  if (actionCount > 0 || spot.note.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('🕹️ $actionCount',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                          if (spot.note.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Text('📝',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ]
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HandEditorScreen(spot: spot)),
                          );
                          widget.onHandEdited?.call();
                        },
                        child: const Text('✏️ Edit Hand'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Duplicate',
                        icon: const Icon(Icons.copy),
                        onPressed: _duplicate,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'mistake') {
                            if (!spot.tags.contains('Mistake')) {
                              setState(() => spot.tags.add('Mistake'));
                              await context
                                  .read<EvaluationExecutorService>()
                                  .evaluateSingle(context, spot);
                              widget.onPersist?.call();
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'mistake',
                            child: Text('Mark as Mistake'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (barColor != null)
              Container(height: 4, color: barColor),
            if (recent && !needsWarning && !spot.pinned)
              Positioned(
                right: 4,
                bottom: barColor != null ? 8 : 4,
                child: const Icon(Icons.edit_note,
                    color: Colors.blue, size: 16),
              ),
          ),
          if (spot.pinned)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '📌 Pinned',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (needsWarning)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'EV or ICM is missing or outdated',
                      ),
                      action: SnackBarAction(
                        label: 'Fix',
                        onPressed: () async {
                          await context
                              .read<EvaluationExecutorService>()
                              .evaluateSingle(context, widget.spot);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  );
                },
                child:
                    const Icon(Icons.error_outline, color: Colors.redAccent),
              ),
            ),
          // removed outdated badge
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _priorityColor(spot.priority),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${spot.priority}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
