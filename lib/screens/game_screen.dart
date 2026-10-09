import 'package:flutter/material.dart';
import 'dart:math';
import '../audio.dart';
import '../design.dart';
import '../engine.dart';
import '../game_controller.dart';
import '../scores.dart';
import '../widgets/wood.dart';
import 'gameover_screen.dart';
import 'settings_screen.dart';

/// Gameplay screen: recessed walnut 8x8 mortise tray, kraft score plaques,
/// combo tag, staging tray with 3 oak pieces (drag or tap to place),
/// pause/rotate/hint knobs, MENU chip, pause overlay.
class GameScreen extends StatefulWidget {
  final bool daily;
  final String? dailyDate;
  const GameScreen({super.key, this.daily = false, this.dailyDate});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameController _c;
  final _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c = GameController(daily: widget.daily, dailyDate: widget.dailyDate);
    _c.addListener(_onGameOver);
  }

  void _onGameOver() {
    if (_c.gameOver && mounted) {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              score: _c.score,
              isBest: _c.newBest,
              piecesPlaced: _c.engine.piecesPlaced,
              linesCleared: _c.engine.linesCleared,
              bestCombo: _c.engine.bestCombo,
              level: _c.engine.level,
              daily: widget.daily,
              dailyDate: widget.dailyDate,
            ),
          ),
        );
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // RULES.md §12: interrupting mid-drag cancels the drag, no state changes.
    if (state == AppLifecycleState.paused) {
      _c.cancelDrag();
      if (!_c.gameOver) _c.setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_onGameOver);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return Scaffold(
          body: WorkbenchBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _topRail(),
                      const SizedBox(height: 6),
                      Expanded(child: Center(child: _board())),
                      const SizedBox(height: 6),
                      _hintBar(),
                      const SizedBox(height: 4),
                      _tray(),
                      const SizedBox(height: 6),
                      _toolRail(),
                      const SizedBox(height: 10),
                    ],
                  ),
                  if (_c.dragging) _dragOverlay(),
                  if (_c.popupText != null) _popup(),
                  if (_c.paused) _pauseOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- top rail -----------------------------------------------------------

  Widget _topRail() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          KraftPlaque(
            tilt: -0.02,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              children: [
                Text('SCORE', style: Workshop.label(10)),
                Text('${_c.score}', style: Workshop.digits(24)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _levelStrip()),
          const SizedBox(width: 8),
          Column(
            children: [
              WoodKnob(
                  icon: Icons.pause,
                  size: 46,
                  onTap: () {
                    Sound.I.click();
                    _c.setPaused(true);
                  }),
              const SizedBox(height: 2),
              ComboTag(combo: _c.engine.combo),
            ],
          ),
        ],
      ),
    );
  }

  /// Carpenter's ruler craftsman-level progress strip.
  Widget _levelStrip() {
    final level = _c.engine.level;
    final progress = (_c.score % 500) / 500;
    final title = BlockFillEngine.titleFor(_c.score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Workshop.kraftDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Workshop.walnut, width: 2),
        boxShadow: Workshop.insetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('LV $level · $title',
              style: Workshop.label(11), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          SizedBox(
            height: 10,
            child: CustomPaint(
              painter: _RulerPainter(progress: progress),
              child: const SizedBox.expand(),
            ),
          ),
          Text('BEST ${_c.best}', style: Workshop.digits(13)),
        ],
      ),
    );
  }

  // --- board --------------------------------------------------------------

  Widget _board() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide.clamp(280.0, 520.0);
        final cell = (side - 20) / 8;
        return Container(
          key: _boardKey,
          width: side,
          height: side,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Workshop.walnut,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2E1D0E), width: 3),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 16,
                  offset: Offset(0, 8)),
              BoxShadow(
                  color: Color(0x33F2B950),
                  blurRadius: 4,
                  offset: Offset(-2, -2)),
            ],
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final cellPos = _cellFromLocal(d.localPosition, cell);
              if (cellPos != null) _c.tapBoard(cellPos.$1, cellPos.$2);
            },
            child: Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: 64,
                  itemBuilder: (_, i) => _boardCell(i, cell),
                ),
                SawdustMotes(active: _c.aboutToClear.isNotEmpty),
              ],
            ),
          ),
        );
      },
    );
  }

  (int, int)? _cellFromLocal(Offset local, double cellWithGap) {
    const pad = 10.0;
    final pitch = cellWithGap + 3;
    final x = local.dx - pad, y = local.dy - pad;
    if (x < 0 || y < 0) return null;
    final c = (x / pitch).floor(), r = (y / pitch).floor();
    if (r < 0 || r > 7 || c < 0 || c > 7) return null;
    return (r, c);
  }

  Widget _boardCell(int i, double cell) {
    final cb = ScoreStore.I.colorBlind;
    if (_c.sweepAnim.containsKey(i)) {
      // Sweep: cleared block shrinks away with a puff of sawdust color.
      return TweenAnimationBuilder<double>(
        key: ValueKey('sweep-${_c.sweepId}-$i'),
        tween: Tween(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 380),
        builder: (_, s, _) => Transform.scale(
          scale: s,
          child: Opacity(
            opacity: s,
            child: CustomPaint(
              painter: PiecePainter(
                shape: const PieceShape([Point(0, 0)], 1, 1),
                stain: stainColor(_c.sweepAnim[i]!, cb),
                cell: cell,
                knotIndex: -1,
              ),
            ),
          ),
        ),
      );
    }
    final stain = _c.engine.board[i];
    if (stain >= 0) {
      return CustomPaint(
        painter: PiecePainter(
          shape: const PieceShape([Point(0, 0)], 1, 1),
          stain: stainColor(stain, cb),
          cell: cell,
          knotIndex: -1,
        ),
      );
    }
    if (_c.ghostCells.contains(i)) {
      final t = _c.selected >= 0 ? _c.engine.tray[_c.selected] : null;
      return CustomPaint(
        painter: PiecePainter(
          shape: const PieceShape([Point(0, 0)], 1, 1),
          stain: t == null
              ? Workshop.lampAmber
              : stainColor(t.stain, cb),
          cell: cell,
          ghost: true,
          knotIndex: -1,
        ),
      );
    }
    return MortiseCell(size: cell, warm: _c.aboutToClear.contains(i));
  }

  // --- hint bar -----------------------------------------------------------

  Widget _hintBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _c.hintMsg,
        style: Workshop.body(13,
            color: Workshop.sawdust.withValues(alpha: 0.95)),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // --- tray ---------------------------------------------------------------

  Widget _tray() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotW = (constraints.maxWidth - 32) / 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) _traySlot(i, slotW),
          ],
        );
      },
    );
  }

  Widget _traySlot(int i, double slotW) {
    final t = _c.engine.tray[i];
    final selected = _c.selected == i && t != null;
    final cellSize = (slotW - 24) / 5;
    return GestureDetector(
      onTap: () => _c.selectPiece(i),
      onDoubleTap: () {
        _c.selectPiece(i);
        _c.rotateSelected();
      },
      onPanStart: (d) => _c.beginDrag(i, d.globalPosition.dx, d.globalPosition.dy),
      onPanUpdate: (d) {
        final cellPos = _cellFromGlobal(d.globalPosition);
        _c.updateDrag(d.globalPosition.dx, d.globalPosition.dy,
            cellPos?.$1 ?? -1, cellPos?.$2 ?? -1);
      },
      onPanEnd: (_) => _c.endDrag(),
      onPanCancel: () => _c.cancelDrag(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: slotW,
        height: 108,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        transform: Matrix4.translationValues(0, selected ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF5E3B1C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Workshop.lampAmber : Workshop.walnut,
            width: selected ? 2.5 : 2,
          ),
          boxShadow:
              selected ? Workshop.liftedShadow : Workshop.insetShadow,
        ),
        alignment: Alignment.center,
        child: t == null
            ? Icon(Icons.check,
                color: Workshop.sage.withValues(alpha: 0.8), size: 26)
            : Opacity(
                opacity: _c.dragging && selected ? 0.25 : 1.0,
                child: PieceView(
                  piece: _displayPiece(t),
                  cellSize: cellSize,
                  lifted: selected,
                ),
              ),
      ),
    );
  }

  /// Piece rendered with the player's chosen stain swatch.
  TrayPiece _displayPiece(TrayPiece t) =>
      TrayPiece(t.shape, ScoreStore.I.stainChoice);

  (int, int)? _cellFromGlobal(Offset global) {
    final box =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    const pad = 10.0;
    final boardSize = box.size.width;
    final pitch = (boardSize - 20) / 8 + 3;
    final x = local.dx - pad, y = local.dy - pad;
    if (x < 0 || y < 0) return null;
    final c = (x / pitch).floor(), r = (y / pitch).floor();
    if (r < 0 || r > 7 || c < 0 || c > 7) return null;
    return (r, c);
  }

  Widget _dragOverlay() {
    final t = _c.selected >= 0 ? _c.engine.tray[_c.selected] : null;
    if (t == null) return const SizedBox.shrink();
    const cellSize = 34.0;
    final w = t.shape.w * cellSize, h = t.shape.h * cellSize;
    return Positioned(
      left: _c.dragX - w / 2,
      top: _c.dragY - h / 2 - 30,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: 0.04,
          child: Transform.scale(
            scale: 1.06,
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 20,
                      offset: Offset(8, 14)),
                ],
              ),
              child: PieceView(
                piece: _displayPiece(t),
                cellSize: cellSize,
                lifted: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- tool rail ----------------------------------------------------------

  Widget _toolRail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WoodKnob(
            icon: Icons.rotate_right,
            onTap: () {
              if (_c.selected < 0) {
                _c.setHint('Pick up a block first, then spin it');
                return;
              }
              _c.rotateSelected();
            }),
        const SizedBox(width: 18),
        WoodKnob(icon: Icons.lightbulb_outline, onTap: _c.showHint),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: () {
            Sound.I.click();
            _c.setPaused(true);
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen()));
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Workshop.kraft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Workshop.walnut, width: 2),
              boxShadow: Workshop.restingShadow,
            ),
            child: Text('MENU', style: Workshop.label(13)),
          ),
        ),
      ],
    );
  }

  // --- overlays -----------------------------------------------------------

  Widget _popup() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.32,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_c.popupId),
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 220),
            builder: (_, s, _) => Transform.scale(
              scale: s,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Workshop.brickRed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Workshop.walnut, width: 2),
                  boxShadow: Workshop.liftedShadow,
                ),
                child: Text(
                  _c.popupText!,
                  style: Workshop.burned(20, color: Workshop.sawdust),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: KraftPlaque(
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('BENCH PAUSED', style: Workshop.burned(26)),
              const SizedBox(height: 6),
              Text('The sawdust settles…',
                  style: Workshop.body(14,
                      color:
                          Workshop.burntUmber.withValues(alpha: 0.75))),
              const SizedBox(height: 18),
              OakButton(
                  label: 'RESUME',
                  width: 200,
                  fontSize: 20,
                  onTap: () {
                    Sound.I.click();
                    _c.setPaused(false);
                  }),
              const SizedBox(height: 10),
              OakButton(
                  label: 'RESTART',
                  width: 200,
                  fontSize: 20,
                  onTap: () {
                    Sound.I.click();
                    _c.setPaused(false);
                    _c.newGame();
                  }),
              const SizedBox(height: 10),
              OakButton(
                  label: 'SETTINGS',
                  width: 200,
                  fontSize: 20,
                  onTap: () {
                    Sound.I.click();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SettingsScreen()));
                  }),
              const SizedBox(height: 10),
              _PlankTextButton(
                label: 'QUIT TO MENU',
                onTap: () {
                  Sound.I.click();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlankTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PlankTextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: Workshop.label(14,
              color: Workshop.brickRed)),
    );
  }
}

/// Carpenter's ruler strip painter: tick marks + brass progress marker.
class _RulerPainter extends CustomPainter {
  final double progress;
  _RulerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final tick = Paint()
      ..color = Workshop.burntUmber.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (var i = 0; i <= 20; i++) {
      final x = size.width * i / 20;
      final tall = i % 5 == 0;
      canvas.drawLine(
          Offset(x, 0), Offset(x, tall ? size.height : size.height * 0.5), tick);
    }
    final mx = size.width * progress.clamp(0.0, 1.0);
    final marker = Paint()..color = Workshop.brass;
    canvas.drawCircle(Offset(mx, size.height / 2), 4.5, marker);
    canvas.drawCircle(
        Offset(mx, size.height / 2),
        4.5,
        Paint()
          ..color = Workshop.walnut
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.progress != progress;
}
