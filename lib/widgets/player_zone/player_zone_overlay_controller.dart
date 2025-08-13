part of 'player_zone_core.dart';

class PlayerZoneOverlayController {
  PlayerZoneOverlayController(this._state);

  final _PlayerZoneWidgetState _state;

  OverlayEntry? _betEntry;
  OverlayEntry? _betOverlayEntry;
  OverlayEntry? _actionLabelEntry;
  OverlayEntry? _refundMessageEntry;
  OverlayEntry? _lossAmountEntry;
  OverlayEntry? _gainAmountEntry;
  OverlayEntry? _chipWinEntry;
  OverlayEntry? _foldChipEntry;
  OverlayEntry? _showdownLossEntry;
  bool _winChipsAnimating = false;
  final List<OverlayEntry> _winChipEntries = [];

  void playBetAnimation(int amount) {
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final start =
        box.localToGlobal(Offset(box.size.width / 2, 20 * _state.widget.scale));
    final media = MediaQuery.of(_state.context).size;
    final end =
        Offset(media.width / 2, media.height / 2 - 60 * _state.widget.scale);
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          (40 + ChipStackMovingWidget.activeCount * 8) * _state.widget.scale,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BetFlyingChips(
        start: start,
        end: end,
        control: control,
        amount: amount,
        color: Colors.amber,
        scale: _state.widget.scale,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    _betEntry = entry;
  }

  void playBetRefundAnimation(
    int amount, {
    Offset? startPosition,
    Color color = Colors.lightGreenAccent,
    VoidCallback? onCompleted,
  }) {
    final overlay = Overlay.of(_state.context);
    final stackBox =
        _state._stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final media = MediaQuery.of(_state.context).size;
    final start = startPosition ??
        Offset(media.width / 2, media.height / 2 - 60 * _state.widget.scale);
    final end = stackBox.localToGlobal(
        Offset(stackBox.size.width / 2, stackBox.size.height / 2));
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          (40 + RefundChipStackMovingWidget.activeCount * 8) *
              _state.widget.scale,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => RefundChipStackMovingWidget(
        start: start,
        end: end,
        control: control,
        amount: amount,
        color: color,
        scale: _state.widget.scale,
        onCompleted: () {
          entry.remove();
          onCompleted?.call();
        },
      ),
    );
    overlay.insert(entry);
    _betEntry = entry;
  }

  void playBetChipsToCenter(int amount, {Color color = Colors.amber}) {
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final start =
        box.localToGlobal(Offset(box.size.width / 2, 20 * _state.widget.scale));
    final media = MediaQuery.of(_state.context).size;
    final end =
        Offset(media.width / 2, media.height / 2 - 60 * _state.widget.scale);
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          (40 + ChipStackMovingWidget.activeCount * 8) * _state.widget.scale,
    );
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BetToCenterAnimation(
        start: start,
        end: end,
        control: control,
        amount: amount,
        color: color,
        scale: _state.widget.scale,
        fadeStart: 0.8,
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14 * _state.widget.scale,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void showBetOverlay(int amount, Color color) {
    _betOverlayEntry?.remove();
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box
        .localToGlobal(Offset(box.size.width / 2, -16 * _state.widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BetAmountOverlay(
        position: pos,
        amount: amount,
        color: color,
        scale: _state.widget.scale,
        onCompleted: () {
          entry.remove();
          if (_betOverlayEntry == entry) _betOverlayEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _betOverlayEntry = entry;
  }

  void showRefundMessage(int amount) {
    _refundMessageEntry?.remove();
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box
        .localToGlobal(Offset(box.size.width / 2, -16 * _state.widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => RefundMessageOverlay(
        position: pos,
        amount: amount,
        scale: _state.widget.scale,
        onCompleted: () {
          entry.remove();
          if (_refundMessageEntry == entry) _refundMessageEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _refundMessageEntry = entry;
  }

  void showLossAmount(int amount) {
    _lossAmountEntry?.remove();
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box
        .localToGlobal(Offset(box.size.width / 2, -16 * _state.widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => LossAmountWidget(
        position: pos,
        amount: amount,
        scale: _state.widget.scale,
        onCompleted: () {
          entry.remove();
          if (_lossAmountEntry == entry) _lossAmountEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _lossAmountEntry = entry;
  }

  void showGainAmount(int amount) {
    _gainAmountEntry?.remove();
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box
        .localToGlobal(Offset(box.size.width / 2, -16 * _state.widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GainAmountWidget(
        position: pos,
        amount: amount,
        scale: _state.widget.scale,
        onCompleted: () {
          entry.remove();
          if (_gainAmountEntry == entry) _gainAmountEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _gainAmountEntry = entry;
  }

  void showActionLabel(String text, Color color) {
    _actionLabelEntry?.remove();
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box
        .localToGlobal(Offset(box.size.width / 2, -32 * _state.widget.scale));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ActionLabelOverlay(
        position: pos,
        text: text,
        color: color,
        scale: _state.widget.scale,
        onCompleted: () {
          entry.remove();
          if (_actionLabelEntry == entry) _actionLabelEntry = null;
        },
      ),
    );
    overlay.insert(entry);
    _actionLabelEntry = entry;
  }

  void clearActionLabel() {
    _actionLabelEntry?.remove();
    _actionLabelEntry = null;
  }

  void startChipWinAnimation() {
    final overlay = Overlay.of(_state.context);
    final box =
        _state._stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final media = MediaQuery.of(_state.context).size;
    final start =
        Offset(media.width / 2, media.height / 2 - 60 * _state.widget.scale);
    final end = box.localToGlobal(box.size.center(Offset.zero));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ChipWinOverlay(
        animation: _state._chipWinController,
        start: start,
        end: end,
        scale: _state.widget.scale,
      ),
    );
    overlay.insert(entry);
    _chipWinEntry = entry;
    _state._chipWinController.forward(from: 0.0).whenComplete(() {
      entry.remove();
      if (_chipWinEntry == entry) _chipWinEntry = null;
    });
  }

  void startFoldChipAnimation() {
    final overlay = Overlay.of(_state.context);
    final box =
        _state._stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final media = MediaQuery.of(_state.context).size;
    final start = box.localToGlobal(box.size.center(Offset.zero));
    final end =
        Offset(media.width / 2, media.height / 2 - 60 * _state.widget.scale);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => FoldChipOverlay(
        animation: _state._foldChipController,
        start: start,
        end: end,
        scale: _state.widget.scale,
      ),
    );
    overlay.insert(entry);
    _foldChipEntry = entry;
    _state._foldChipController.forward(from: 0.0).whenComplete(() {
      entry.remove();
      if (_foldChipEntry == entry) _foldChipEntry = null;
    });
  }

  void startShowdownLossAnimation() {
    final overlay = Overlay.of(_state.context);
    final box =
        _state._stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final media = MediaQuery.of(_state.context).size;
    final start = box.localToGlobal(box.size.center(Offset.zero));
    final end =
        Offset(media.width / 2, media.height / 2 - 60 * _state.widget.scale);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => FoldChipOverlay(
        animation: _state._showdownLossController,
        start: start,
        end: end,
        scale: _state.widget.scale,
      ),
    );
    overlay.insert(entry);
    _showdownLossEntry = entry;
    _state._showdownLossController.forward(from: 0.0).whenComplete(() {
      entry.remove();
      if (_showdownLossEntry == entry) _showdownLossEntry = null;
    });
  }

  void playWinChipsAnimation(int amount) {
    if (_winChipsAnimating) return;
    final overlay = Overlay.of(_state.context);
    final box = _state.context.findRenderObject() as RenderBox?;
    if (box == null) return;

    _state._stackWinController.forward(from: 0.0);

    _winChipsAnimating = true;
    final media = MediaQuery.of(_state.context).size;
    final start =
        Offset(media.width / 2, media.height / 2 - 60 * _state.widget.scale);
    final end = box.localToGlobal(box.size.center(Offset.zero));
    final rnd = Random();
    final chipCount = 6 + rnd.nextInt(3);
    for (int i = 0; i < chipCount; i++) {
      Future.delayed(Duration(milliseconds: 50 * i), () {
        if (!_state.mounted) return;
        final control = Offset(
          (start.dx + end.dx) / 2 +
              (rnd.nextDouble() * 40 - 20) * _state.widget.scale,
          (start.dy + end.dy) / 2 -
              (40 + ChipMovingWidget.activeCount * 8) * _state.widget.scale,
        );
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => WinnerFlyingChip(
            start: start,
            end: end,
            control: control,
            scale: _state.widget.scale,
            onCompleted: () {
              entry.remove();
              _winChipEntries.remove(entry);
              if (_winChipEntries.isEmpty) {
                _winChipsAnimating = false;
              }
            },
          ),
        );
        overlay.insert(entry);
        _winChipEntries.add(entry);
      });
    }
  }

  void dispose() {
    _betEntry?.remove();
    _betOverlayEntry?.remove();
    _actionLabelEntry?.remove();
    _refundMessageEntry?.remove();
    _lossAmountEntry?.remove();
    _gainAmountEntry?.remove();
    _chipWinEntry?.remove();
    _foldChipEntry?.remove();
    _showdownLossEntry?.remove();
    for (final e in _winChipEntries) {
      e.remove();
    }
  }
}
