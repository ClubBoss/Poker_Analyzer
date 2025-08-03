part of 'player_zone_core.dart';

class PlayerZoneAnimationController {
  PlayerZoneAnimationController(this._state);

  final _PlayerZoneWidgetState _state;
  bool winnerHighlight = false;
  Timer? _highlightTimer;
  bool refundGlow = false;
  Timer? _refundGlowTimer;

  void highlightWinner() {
    if (_state.widget.isHero) return;
    _highlightTimer?.cancel();
    _state.setState(() => winnerHighlight = true);
    _state._animations.playWinnerGlow();
    _state._animations.playWinnerHighlight();
    _state._overlayController.startChipWinAnimation();
    _state._showWinnerLabelAnimated();
    if (_state._wasAllIn) {
      _state._animations.playAllInWinGlow();
      _state._wasAllIn = false;
    }
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_state.mounted) _state.setState(() => winnerHighlight = false);
    });
  }

  void clearWinnerHighlight() {
    _highlightTimer?.cancel();
    _state._animations.resetWinnerGlow();
    _state._animations.resetWinnerHighlight();
    if (winnerHighlight) {
      _state.setState(() => winnerHighlight = false);
    }
  }

  void showRefundGlow() {
    _refundGlowTimer?.cancel();
    _state.setState(() => refundGlow = true);
    _refundGlowTimer = Timer(const Duration(milliseconds: 800), () {
      if (_state.mounted) _state.setState(() => refundGlow = false);
    });
  }

  Future<void> playWinnerBounce() async {
    await _state._bounceController.forward(from: 0.0);
  }

  void dispose() {
    _highlightTimer?.cancel();
    _refundGlowTimer?.cancel();
  }
}
