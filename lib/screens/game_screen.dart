import 'package:flutter/material.dart';
import 'dart:math';
import '../design.dart';
import '../engine.dart';
import '../game_controller.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/workshop_themes.dart';
import '../widgets/wood.dart';
import 'gameover_screen.dart';
import 'settings_screen.dart';

/// Gameplay screen: recessed 8x8 mortise tray, kraft score plaques, combo tag,
/// blitz timer, staging tray with 3 pieces (drag or tap to place), sawdust
/// particle bursts on clear, combo celebrations, pause/rotate/hint knobs.
class GameScreen extends StatefulWidget {
  final GameMode mode;
  final String? dailyDate;
  final WorkshopAudio audio;
  final BlockFillSettings settings;
  const GameScreen({
    super.key,
    required this.mode,
    required this.audio,
    required this.settings,
    this.dailyDate,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameController _c;
  final _boardKey = GlobalKey();

  WorkshopThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c = GameController(
      mode: widget.mode,
      dailyDate: widget.dailyDate,
      audio: widget.audio,
      settings: widget.settings,
    );
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
              timedOut: _c.gameOverByTimeout,
              piecesPlaced: _c.engine.piecesPlaced,
              linesCleared: _c.engine.linesCleared,
              bestCombo: _c.engine.bestCombo,
              level: _c.engine.level,
              mode: widget.mode,
              dailyDate: widget.dailyDate,
              audio: widget.audio,
              settings: widget.settings,
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

  BlockStyleDef _styleOf(int i) =>
      styleFor(i, widget.settings.colorBlind);

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return Scaffold(
          body: WorkbenchBackground(
            theme: t,
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _topRail(t),
                      const SizedBox(height: 6),
                      Expanded(child: Center(child: _board(t))),
                      const SizedBox(height: 6),
                      _hintBar(t),
                      const SizedBox(height: 4),
                      _tray(t),
                      const SizedBox(height: 6),
                      _toolRail(t),
                      const SizedBox(height: 10),
                    ],
                  ),
                  if (_c.dragging) _dragOverlay(t),
                  if (_c.popupText != null) _popup(t),
                  if (_c.celebrateCombo >= 2)
                    Center(
                      child: ComboCelebration(
                        key: ValueKey('cel-${_c.celebrateId}'),
                        combo: _c.celebrateCombo,
                        celebrateId: _c.celebrateId,
                        theme: t,
                      ),
                    ),
                  if (_c.paused) _pauseOverlay(t),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- top rail -----------------------------------------------------------

  Widget _topRail(WorkshopThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          KraftPlaque(
            theme: t,
            tilt: -0.02,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              children: [
                Text('SCORE', style: Workshop.label(10, color: t.textSoft)),
                Text('${_c.score}',
                    style: Workshop.digits(24, color: t.text)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: widget.mode == GameMode.blitz
                  ? _blitzTimer(t)
                  : _levelStrip(t)),
          const SizedBox(width: 8),
          Column(
            children: [
              WoodKnob(
                  theme: t,
                  icon: Icons.pause,
                  size: 46,
                  onTap: () {
                    widget.audio.click();
                    _c.setPaused(true);
                  }),
              const SizedBox(height: 2),
              ComboTag(combo: _c.engine.combo, theme: t),
            ],
          ),
        ],
      ),
    );
  }

  /// Blitz countdown plaque: mm:ss, turns urgent under 15s.
  Widget _blitzTimer(WorkshopThemeDef t) {
    final secs = (_c.engine.timeLeftMs / 1000).ceil();
    final mm = secs ~/ 60;
    final ss = (secs % 60).toString().padLeft(2, '0');
    final urgent = secs <= 15;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: urgent ? t.comboRed : t.kraftDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.trayFrame, width: 2),
        boxShadow: Workshop.insetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('BLITZ',
              style: Workshop.label(11,
                  color: urgent ? t.kraft : t.text)),
          Text('$mm:$ss',
              style: Workshop.digits(26,
                  color: urgent ? t.kraft : t.text)),
          Text('BEST ${_c.best}',
              style: Workshop.digits(13,
                  color: (urgent ? t.kraft : t.text)
                      .withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  /// Carpenter's ruler craftsman-level progress strip.
  Widget _levelStrip(WorkshopThemeDef t) {
    final level = _c.engine.level;
    final progress = (_c.score % 500) / 500;
    final title = BlockFillEngine.titleFor(_c.score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.kraftDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.trayFrame, width: 2),
        boxShadow: Workshop.insetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('LV $level · $title',
              style: Workshop.label(11, color: t.text),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          SizedBox(
            height: 10,
            child: CustomPaint(
              painter: _RulerPainter(progress: progress, t: t),
              child: const SizedBox.expand(),
            ),
          ),
          Text('BEST ${_c.best}',
              style: Workshop.digits(13, color: t.text)),
        ],
      ),
    );
  }

  // --- board --------------------------------------------------------------

  Widget _board(WorkshopThemeDef t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide.clamp(280.0, 520.0);
        final cell = (side - 20) / 8;
        final accent = BoardAccents.byIndex(widget.settings.boardAccentId);
        return Container(
          key: _boardKey,
          width: side,
          height: side,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.frame,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.text, width: 3),
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
                  itemBuilder: (_, i) => _boardCell(i, cell, t),
                ),
                SawdustMotes(
                    active: _c.aboutToClear.isNotEmpty, theme: t),
                if (_c.burstCells.isNotEmpty)
                  ClearBurst(
                    key: ValueKey('burst-${_c.burstId}'),
                    cells: {
                      for (final e in _c.burstCells.entries)
                        e.key: _styleOf(e.value).mid,
                    },
                    pitch: cell + 3,
                    burstId: _c.burstId,
                    theme: t,
                  ),
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

  Widget _boardCell(int i, double cell, WorkshopThemeDef t) {
    if (_c.sweepAnim.containsKey(i)) {
      // Sweep: cleared block shrinks away.
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
                style: _styleOf(_c.sweepAnim[i]!),
                cell: cell,
                knotIndex: -1,
                ghostTint: t.lampAmber,
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
          style: _styleOf(stain),
          cell: cell,
          knotIndex: -1,
          ghostTint: t.lampAmber,
        ),
      );
    }
    if (_c.ghostCells.contains(i)) {
      final tp = _c.selected >= 0 ? _c.engine.tray[_c.selected] : null;
      return CustomPaint(
        painter: PiecePainter(
          shape: const PieceShape([Point(0, 0)], 1, 1),
          style: tp == null
              ? BlockStyleDef(
                  name: 'ghost', light: t.lampAmber, mid: t.lampAmber, dark: t.lampAmber)
              : _styleOf(tp.stain),
          cell: cell,
          ghost: true,
          ghostTint: t.lampAmber,
          knotIndex: -1,
        ),
      );
    }
    return MortiseCell(size: cell, warm: _c.aboutToClear.contains(i), theme: t);
  }

  // --- hint bar -----------------------------------------------------------

  Widget _hintBar(WorkshopThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _c.hintMsg,
        style: Workshop.body(13,
            color: t.accentLight.withValues(alpha: 0.95)),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // --- tray ---------------------------------------------------------------

  Widget _tray(WorkshopThemeDef t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotW = (constraints.maxWidth - 32) / 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) _traySlot(i, slotW, t),
          ],
        );
      },
    );
  }

  Widget _traySlot(int i, double slotW, WorkshopThemeDef t) {
    final tp = _c.engine.tray[i];
    final selected = _c.selected == i && tp != null;
    final cellSize = (slotW - 24) / 5;
    return GestureDetector(
      onTap: () => _c.selectPiece(i),
      onDoubleTap: () {
        _c.selectPiece(i);
        _c.rotateSelected();
      },
      onPanStart: (d) =>
          _c.beginDrag(i, d.globalPosition.dx, d.globalPosition.dy),
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
          color: t.trayInset,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? t.lampAmber : t.trayFrame,
            width: selected ? 2.5 : 2,
          ),
          boxShadow:
              selected ? Workshop.liftedShadow : Workshop.insetShadow,
        ),
        alignment: Alignment.center,
        child: tp == null
            ? Icon(Icons.check,
                color: t.sage.withValues(alpha: 0.8), size: 26)
            : Opacity(
                opacity: _c.dragging && selected ? 0.25 : 1.0,
                child: PieceView(
                  piece: tp,
                  cellSize: cellSize,
                  style: _styleOf(tp.stain),
                  lifted: selected,
                  ghostTint: t.lampAmber,
                ),
              ),
      ),
    );
  }

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

  Widget _dragOverlay(WorkshopThemeDef t) {
    final tp = _c.selected >= 0 ? _c.engine.tray[_c.selected] : null;
    if (tp == null) return const SizedBox.shrink();
    const cellSize = 34.0;
    final w = tp.shape.w * cellSize, h = tp.shape.h * cellSize;
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
                piece: tp,
                cellSize: cellSize,
                style: _styleOf(tp.stain),
                lifted: true,
                ghostTint: t.lampAmber,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- tool rail ----------------------------------------------------------

  Widget _toolRail(WorkshopThemeDef t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WoodKnob(
            theme: t,
            icon: Icons.rotate_right,
            onTap: () {
              if (_c.selected < 0) {
                _c.setHint('Pick up a block first, then spin it');
                return;
              }
              _c.rotateSelected();
            }),
        const SizedBox(width: 18),
        WoodKnob(theme: t, icon: Icons.lightbulb_outline, onTap: _c.showHint),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: () {
            widget.audio.click();
            _c.setPaused(true);
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettingsScreen(
                      audio: widget.audio,
                      settings: widget.settings,
                    )));
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: t.kraft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: t.trayFrame, width: 2),
              boxShadow: Workshop.restingShadow,
            ),
            child: Text('MENU', style: Workshop.label(13, color: t.text)),
          ),
        ),
      ],
    );
  }

  // --- overlays -----------------------------------------------------------

  Widget _popup(WorkshopThemeDef t) {
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
                  color: t.comboRed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: t.trayFrame, width: 2),
                  boxShadow: Workshop.liftedShadow,
                ),
                child: Text(
                  _c.popupText!,
                  style: Workshop.burned(20, color: t.kraft),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay(WorkshopThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: KraftPlaque(
          theme: t,
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('BENCH PAUSED',
                  style: Workshop.burned(26, color: t.text)),
              const SizedBox(height: 6),
              Text('The sawdust settles…',
                  style: Workshop.body(14, color: t.textSoft)),
              const SizedBox(height: 18),
              OakButton(
                  theme: t,
                  label: 'RESUME',
                  width: 200,
                  fontSize: 20,
                  onTap: () {
                    widget.audio.click();
                    _c.setPaused(false);
                  }),
              const SizedBox(height: 10),
              OakButton(
                  theme: t,
                  label: 'RESTART',
                  width: 200,
                  fontSize: 20,
                  onTap: () {
                    widget.audio.click();
                    _c.setPaused(false);
                    _c.newGame();
                  }),
              const SizedBox(height: 10),
              OakButton(
                  theme: t,
                  label: 'SETTINGS',
                  width: 200,
                  fontSize: 20,
                  onTap: () {
                    widget.audio.click();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: widget.settings,
                            )));
                  }),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                },
                child: Text('QUIT TO MENU',
                    style: Workshop.label(14, color: t.comboRed)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carpenter's ruler strip painter: tick marks + brass progress marker.
class _RulerPainter extends CustomPainter {
  final double progress;
  final WorkshopThemeDef t;
  _RulerPainter({required this.progress, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final tick = Paint()
      ..color = t.text.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (var i = 0; i <= 20; i++) {
      final x = size.width * i / 20;
      final tall = i % 5 == 0;
      canvas.drawLine(
          Offset(x, 0), Offset(x, tall ? size.height : size.height * 0.5), tick);
    }
    final mx = size.width * progress.clamp(0.0, 1.0);
    final marker = Paint()..color = t.accent;
    canvas.drawCircle(Offset(mx, size.height / 2), 4.5, marker);
    canvas.drawCircle(
        Offset(mx, size.height / 2),
        4.5,
        Paint()
          ..color = t.trayFrame
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.progress != progress || old.t != t;
}
