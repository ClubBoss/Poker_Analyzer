part of 'player_zone_core.dart';

mixin PlayerZoneAnimator on State<PlayerZoneWidget> {
  void highlightWinner() {
    if (widget.isHero) return;
    _highlightTimer?.cancel();
    setState(() => _winnerHighlight = true);
    _animations.playWinnerGlow();
    _animations.playWinnerHighlight();
    _startChipWinAnimation();
    _showWinnerLabelAnimated();
    if (_wasAllIn) {
      _animations.playAllInWinGlow();
      _wasAllIn = false;
    }
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _winnerHighlight = false);
    });
  }

  void _startChipWinAnimation() {
    final overlay = Overlay.of(context);
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final media = MediaQuery.of(context).size;
    final start = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    final end = box.localToGlobal(box.size.center(Offset.zero));
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ChipWinOverlay(
        animation: _chipWinController,
        start: start,
        end: end,
        scale: widget.scale,
      ),
    );
    overlay.insert(entry);
    _chipWinEntry = entry;
    _chipWinController.forward(from: 0.0).whenComplete(() {
      entry.remove();
      if (_chipWinEntry == entry) _chipWinEntry = null;
    });
  }

  void _startFoldChipAnimation() {
    final overlay = Overlay.of(context);
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final media = MediaQuery.of(context).size;
    final start = box.localToGlobal(box.size.center(Offset.zero));
    final end = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FoldChipOverlay(
        animation: _foldChipController,
        start: start,
        end: end,
        scale: widget.scale,
      ),
    );
    overlay.insert(entry);
    _foldChipEntry = entry;
    _foldChipController.forward(from: 0.0).whenComplete(() {
      entry.remove();
      if (_foldChipEntry == entry) _foldChipEntry = null;
    });
  }

  void _startShowdownLossAnimation() {
    final overlay = Overlay.of(context);
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final media = MediaQuery.of(context).size;
    final start = box.localToGlobal(box.size.center(Offset.zero));
    final end = Offset(media.width / 2, media.height / 2 - 60 * widget.scale);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FoldChipOverlay(
        animation: _showdownLossController,
        start: start,
        end: end,
        scale: widget.scale,
      ),
    );
    overlay.insert(entry);
    _showdownLossEntry = entry;
    _showdownLossController.forward(from: 0.0).whenComplete(() {
      entry.remove();
      if (_showdownLossEntry == entry) _showdownLossEntry = null;
    });
  }

  void clearWinnerHighlight() {
    _highlightTimer?.cancel();
    _animations.resetWinnerGlow();
    _animations.resetWinnerHighlight();
    if (_winnerHighlight) {
      setState(() => _winnerHighlight = false);
    }
  }

  void showRefundGlow() {
    _refundGlowTimer?.cancel();
    setState(() => _refundGlow = true);
    _refundGlowTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _refundGlow = false);
    });
  }

  Future<void> playWinnerBounce() async {
    await _bounceController.forward(from: 0.0);
  }
}
