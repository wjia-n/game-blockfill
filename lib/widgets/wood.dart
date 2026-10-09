import 'dart:math';
import 'package:flutter/material.dart';
import '../design.dart';
import '../engine.dart';
import '../theme/workshop_themes.dart';

/// Carpenter's workshop widget kit: skeuomorphic painters and tactile
/// controls. Lamp light comes from the top-left everywhere.
/// Every widget takes the active [WorkshopThemeDef] so the 14 themes,
/// 12 block styles and 6 board accents all restyle the game.

/// Block material for a style index, honoring color-blind mode.
BlockStyleDef styleFor(int i, bool colorBlind) {
  if (!colorBlind) return BlockStyles.byIndex(i);
  final c = BlockStyles
      .colorBlind[i.clamp(0, BlockStyles.colorBlind.length - 1)];
  return BlockStyleDef(
    name: 'Safe',
    light: _mix(c, const Color(0xFFFFFFFF), 0.35),
    mid: c,
    dark: _mix(c, const Color(0xFF000000), 0.35),
  );
}

Color _mix(Color a, Color b, double t) => Color.fromARGB(
      0xFF,
      ((a.r * 255.0) + ((b.r - a.r) * 255.0) * t).round().clamp(0, 255),
      ((a.g * 255.0) + ((b.g - a.g) * 255.0) * t).round().clamp(0, 255),
      ((a.b * 255.0) + ((b.b - a.b) * 255.0) * t).round().clamp(0, 255),
    );

// ---------------------------------------------------------------------------
// Workbench background: scarred bench, grain, saw marks, sawdust flecks,
// and a soft warm wash from the top-left lamp.
// ---------------------------------------------------------------------------
class WorkbenchBackground extends StatelessWidget {
  final Widget child;
  final WorkshopThemeDef? theme;
  const WorkbenchBackground({
    super.key,
    required this.child,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? WorkshopThemes.all[0];
    return CustomPaint(
      painter: _WorkbenchPainter(t),
      child: child,
    );
  }
}

class _WorkbenchPainter extends CustomPainter {
  final WorkshopThemeDef t;
  final Random _r = Random(77);
  _WorkbenchPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = t.bench;
    canvas.drawRect(Offset.zero & size, bg);

    // Plank seams (horizontal boards).
    final seam = Paint()
      ..color = t.benchDeep.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    final rows = (size.height / 220).ceil();
    for (var i = 1; i < rows; i++) {
      final y = size.height * i / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), seam);
    }

    // Wood grain: long wavy darker streaks.
    final grain = Paint()
      ..color = t.benchDeep.withValues(alpha: 0.35)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 46; i++) {
      final y0 = _r.nextDouble() * size.height;
      final amp = 3 + _r.nextDouble() * 7;
      final path = Path()..moveTo(-10, y0);
      for (var x = 0.0; x <= size.width + 10; x += 40) {
        path.lineTo(x, y0 + sin(x / 90 + i) * amp);
      }
      canvas.drawPath(path, grain);
    }

    // Saw marks: short diagonal scars.
    final scar = Paint()
      ..color = t.text.withValues(alpha: 0.22)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final x = _r.nextDouble() * size.width;
      final y = _r.nextDouble() * size.height;
      final len = 8 + _r.nextDouble() * 22;
      final a = -0.5 + _r.nextDouble() * 0.3;
      canvas.drawLine(Offset(x, y),
          Offset(x + cos(a) * len, y + sin(a) * len), scar);
    }

    // Sawdust flecks.
    final dust = Paint()..color = t.accentLight.withValues(alpha: 0.5);
    for (var i = 0; i < 120; i++) {
      final x = _r.nextDouble() * size.width;
      final y = _r.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.8 + _r.nextDouble() * 1.6, dust);
    }

    // Warm lamp wash from top-left (subtle warm light tint, not a glow).
    final lamp = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.1, -1.1),
        radius: 1.4,
        colors: [
          t.lampAmber.withValues(alpha: 0.20),
          t.lampAmber.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, lamp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Piece painter: draws a whole polyomino with grain, silhouette bevels
// (light top/left, dark bottom/right) and dovetail edge notches.
// ---------------------------------------------------------------------------
class PiecePainter extends CustomPainter {
  final PieceShape shape;
  final BlockStyleDef style;
  final double cell;
  final bool ghost;
  final int knotIndex; // which cell gets the branded knot (-1 = none)
  final Color ghostTint;

  PiecePainter({
    required this.shape,
    required this.style,
    required this.cell,
    this.ghost = false,
    this.knotIndex = -1,
    this.ghostTint = const Color(0xFFF2B950),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final occ = <String, bool>{};
    for (final p in shape.cells) {
      occ['${p.x},${p.y}'] = true;
    }
    bool has(int x, int y) => occ['$x,$y'] == true;

    final body = Paint()
      ..color = ghost ? style.mid.withValues(alpha: 0.55) : style.mid;
    final rnd = Random(shape.cells.length * 131 + shape.w * 17 + shape.h * 7);

    // Cell bodies.
    for (final p in shape.cells) {
      final r = Rect.fromLTWH(p.x * cell, p.y * cell, cell, cell);
      canvas.drawRect(r, body);
    }

    // Wood grain streaks across the piece.
    final grainPaint = Paint()
      ..color = style.dark.withValues(alpha: ghost ? 0.15 : 0.35)
      ..strokeWidth = max(1.0, cell * 0.045)
      ..style = PaintingStyle.stroke;
    for (var cx = 0; cx < shape.w; cx++) {
      var colHas = false;
      for (final p in shape.cells) {
        if (p.x == cx) colHas = true;
      }
      if (!colHas) continue;
      final gx = cx * cell + cell * (0.3 + rnd.nextDouble() * 0.4);
      var top = shape.h * cell;
      var bottom = 0.0;
      for (final p in shape.cells) {
        if (p.x == cx) {
          top = min(top, p.y * cell);
          bottom = max(bottom, (p.y + 1) * cell);
        }
      }
      final path = Path()..moveTo(gx, top + 1);
      for (var y = top; y <= bottom; y += cell / 3) {
        path.lineTo(gx + sin(y / (cell * 0.8) + cx) * cell * 0.05, y);
      }
      canvas.drawPath(path, grainPaint);
    }

    if (!ghost) {
      // Silhouette bevels: light top/left, dark bottom/right (lamp top-left).
      final hi = Paint()
        ..color = style.light.withValues(alpha: 0.9)
        ..strokeWidth = max(1.2, cell * 0.05);
      final lo = Paint()
        ..color = style.dark.withValues(alpha: 0.85)
        ..strokeWidth = max(1.2, cell * 0.05);
      for (final p in shape.cells) {
        final x = p.x * cell, y = p.y * cell;
        if (!has(p.x, p.y - 1)) {
          canvas.drawLine(Offset(x, y + 1), Offset(x + cell, y + 1), hi);
        }
        if (!has(p.x - 1, p.y)) {
          canvas.drawLine(Offset(x + 1, y), Offset(x + 1, y + cell), hi);
        }
        if (!has(p.x, p.y + 1)) {
          canvas.drawLine(
              Offset(x, y + cell - 1), Offset(x + cell, y + cell - 1), lo);
        }
        if (!has(p.x + 1, p.y)) {
          canvas.drawLine(
              Offset(x + cell - 1, y), Offset(x + cell - 1, y + cell), lo);
        }
      }

      // Dovetail joint notches along silhouette edges.
      final dove = Paint()..color = style.dark.withValues(alpha: 0.85);
      for (final p in shape.cells) {
        final x = p.x * cell, y = p.y * cell;
        final s = cell * 0.22;
        if (!has(p.x, p.y - 1)) _dovetail(canvas, dove, x + cell / 2, y, s, 0);
        if (!has(p.x, p.y + 1)) {
          _dovetail(canvas, dove, x + cell / 2, y + cell, s, 1);
        }
        if (!has(p.x - 1, p.y)) _dovetail(canvas, dove, x, y + cell / 2, s, 2);
        if (!has(p.x + 1, p.y)) {
          _dovetail(canvas, dove, x + cell, y + cell / 2, s, 3);
        }
      }

      // Hot-branded knot mark on one cell.
      if (knotIndex >= 0 && knotIndex < shape.cells.length) {
        final p = shape.cells[knotIndex];
        final cx = p.x * cell + cell / 2;
        final cy = p.y * cell + cell / 2;
        final knot = Paint()..color = style.dark.withValues(alpha: 0.55);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx, cy),
                width: cell * 0.22,
                height: cell * 0.16),
            knot);
      }
    } else {
      // Ghost: warm amber outline instead of bevels.
      final edge = Paint()
        ..color = ghostTint.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final p in shape.cells) {
        canvas.drawRect(
            Rect.fromLTWH(p.x * cell + 1, p.y * cell + 1, cell - 2, cell - 2),
            edge);
      }
    }
  }

  void _dovetail(Canvas c, Paint p, double x, double y, double s, int dir) {
    final path = Path();
    if (dir == 0) {
      path
        ..moveTo(x - s, y)
        ..lineTo(x + s, y)
        ..lineTo(x + s * 0.55, y + s * 0.9)
        ..lineTo(x - s * 0.55, y + s * 0.9)
        ..close();
    } else if (dir == 1) {
      path
        ..moveTo(x - s, y)
        ..lineTo(x + s, y)
        ..lineTo(x + s * 0.55, y - s * 0.9)
        ..lineTo(x - s * 0.55, y - s * 0.9)
        ..close();
    } else if (dir == 2) {
      path
        ..moveTo(x, y - s)
        ..lineTo(x, y + s)
        ..lineTo(x + s * 0.9, y + s * 0.55)
        ..lineTo(x + s * 0.9, y - s * 0.55)
        ..close();
    } else {
      path
        ..moveTo(x, y - s)
        ..lineTo(x, y + s)
        ..lineTo(x - s * 0.9, y + s * 0.55)
        ..lineTo(x - s * 0.9, y - s * 0.55)
        ..close();
    }
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant PiecePainter old) =>
      old.shape != shape ||
      old.style != style ||
      old.ghost != ghost;
}

/// Renders a [TrayPiece] with a block material style.
class PieceView extends StatelessWidget {
  final TrayPiece piece;
  final double cellSize;
  final BlockStyleDef style;
  final bool ghost;
  final bool lifted;
  final Color ghostTint;

  const PieceView({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.style,
    this.ghost = false,
    this.lifted = false,
    this.ghostTint = const Color(0xFFF2B950),
  });

  @override
  Widget build(BuildContext context) {
    final w = piece.shape.w * cellSize;
    final h = piece.shape.h * cellSize;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        size: Size(w, h),
        painter: PiecePainter(
          shape: piece.shape,
          style: style,
          cell: cellSize,
          ghost: ghost,
          ghostTint: ghostTint,
          knotIndex: piece.shape.cells.length ~/ 2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mortise cell: recessed routed cavity in the tray.
// ---------------------------------------------------------------------------
class MortiseCell extends StatelessWidget {
  final double size;
  final bool warm; // about-to-clear warmth
  final WorkshopThemeDef? theme;
  const MortiseCell({
    super.key,
    required this.size,
    this.warm = false,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? WorkshopThemes.all[0];
    return CustomPaint(
      size: Size(size, size),
      painter: _MortisePainter(warm: warm, t: t),
    );
  }
}

class _MortisePainter extends CustomPainter {
  final bool warm;
  final WorkshopThemeDef t;
  _MortisePainter({required this.warm, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(size.width * 0.14));
    canvas.drawRRect(r, Paint()..color = t.trayInset);
    canvas.drawRRect(
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 3));
    final hi = Paint()
      ..color = (warm ? t.lampAmber : t.lampAmber.withValues(alpha: 0.28))
      ..strokeWidth = warm ? 2.4 : 1.4;
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(2, h - 1.4), Offset(w - 2, h - 1.4), hi);
    canvas.drawLine(Offset(w - 1.4, 2), Offset(w - 1.4, h - 2), hi);
    if (warm) {
      canvas.drawRRect(
          r, Paint()..color = t.lampAmber.withValues(alpha: 0.22));
    }
  }

  @override
  bool shouldRepaint(covariant _MortisePainter old) =>
      old.warm != warm || old.t != t;
}

// ---------------------------------------------------------------------------
// Kraft paper plaque with brass pin.
// ---------------------------------------------------------------------------
class KraftPlaque extends StatelessWidget {
  final Widget child;
  final double tilt;
  final EdgeInsets padding;
  final WorkshopThemeDef? theme;
  const KraftPlaque({
    super.key,
    required this.child,
    this.tilt = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? WorkshopThemes.all[0];
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: t.kraft,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: t.kraftDark, width: 1),
          boxShadow: Workshop.restingShadow,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              top: -9,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.accent,
                    border: Border.all(color: t.trayFrame, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 3,
                          offset: Offset(1, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Oak block button: thick beveled block, carved label, sinks 2px on press.
// ---------------------------------------------------------------------------
class OakButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double fontSize;
  final double width;
  final WorkshopThemeDef? theme;
  const OakButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.fontSize = 22,
    this.width = 220,
    this.theme,
  });

  @override
  State<OakButton> createState() => _OakButtonState();
}

class _OakButtonState extends State<OakButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? WorkshopThemes.all[0];
    final c = widget.color ?? t.blockMid;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: EdgeInsets.symmetric(vertical: _down ? 15 : 14),
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            top: BorderSide(color: t.blockLight, width: _down ? 1 : 2),
            left: BorderSide(color: t.blockLight, width: _down ? 1 : 2),
            bottom: BorderSide(color: t.blockDark, width: _down ? 2 : 4),
            right: BorderSide(color: t.blockDark, width: _down ? 2 : 4),
          ),
          boxShadow: _down
              ? const [
                  BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 2,
                      offset: Offset(1, 1)),
                ]
              : Workshop.restingShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Workshop.burned(widget.fontSize, color: t.text),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round wooden knob button (pause / rotate / hint / settings).
// ---------------------------------------------------------------------------
class WoodKnob extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;
  final WorkshopThemeDef? theme;
  const WoodKnob({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.iconColor,
    this.theme,
  });

  @override
  State<WoodKnob> createState() => _WoodKnobState();
}

class _WoodKnobState extends State<WoodKnob> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? WorkshopThemes.all[0];
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.blockMid,
          border: Border.all(color: t.trayFrame, width: 3),
          boxShadow: _down
              ? const [
                  BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 2,
                      offset: Offset(1, 1)),
                ]
              : Workshop.restingShadow,
        ),
        child: CustomPaint(
          painter: _KnobGrainPainter(t),
          child: Icon(widget.icon,
              color: widget.iconColor ?? t.text, size: widget.size * 0.44),
        ),
      ),
    );
  }
}

class _KnobGrainPainter extends CustomPainter {
  final WorkshopThemeDef t;
  _KnobGrainPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ring = Paint()
      ..color = t.blockDark.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(c, r * i / 4.2, ring);
    }
    final hi = Paint()
      ..color = t.blockLight.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 5), pi * 1.05, pi * 0.6, false, hi);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Brass-and-wood bolt-latch toggle.
// ---------------------------------------------------------------------------
class BoltLatch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final WorkshopThemeDef? theme;
  const BoltLatch({
    super.key,
    required this.value,
    required this.onChanged,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? WorkshopThemes.all[0];
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 74,
        height: 36,
        decoration: BoxDecoration(
          color: t.trayInset,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.trayFrame, width: 2),
          boxShadow: Workshop.insetShadow,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? t.accent : t.blockDark,
              border: Border.all(color: t.trayFrame, width: 2),
              boxShadow: Workshop.restingShadow,
            ),
            child: Icon(
              value ? Icons.check : Icons.close,
              size: 16,
              color: t.text,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Planed-wood rail slider with chunky knob.
// ---------------------------------------------------------------------------
class WoodSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final WorkshopThemeDef? theme;
  const WoodSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? WorkshopThemes.all[0];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            final v = (value + d.delta.dx / w).clamp(0.0, 1.0);
            onChanged(v);
          },
          onTapDown: (d) {
            onChanged((d.localPosition.dx / w).clamp(0.0, 1.0));
          },
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: t.blockDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: t.trayFrame, width: 1.5),
                    boxShadow: Workshop.insetShadow,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 8,
                    width: max(8.0, w * value),
                    decoration: BoxDecoration(
                      color: t.accentLight.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: (w - 34) * value,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.blockMid,
                      border: Border.all(color: t.trayFrame, width: 2.5),
                      boxShadow: Workshop.restingShadow,
                    ),
                    child: Icon(Icons.grain, size: 16, color: t.text),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Combo luggage tag.
// ---------------------------------------------------------------------------
class ComboTag extends StatelessWidget {
  final int combo;
  final WorkshopThemeDef? theme;
  const ComboTag({
    super.key,
    required this.combo,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? WorkshopThemes.all[0];
    if (combo < 2) return const SizedBox.shrink();
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: t.comboRed,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: t.trayFrame, width: 1.5),
          boxShadow: Workshop.restingShadow,
        ),
        child: Text(
          'COMBO ×$combo',
          style: Workshop.label(14, color: t.kraft),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating sawdust motes (about-to-clear warmth feedback).
// ---------------------------------------------------------------------------
class SawdustMotes extends StatefulWidget {
  final bool active;
  final WorkshopThemeDef? theme;
  const SawdustMotes({
    super.key,
    required this.active,
    this.theme,
  });

  @override
  State<SawdustMotes> createState() => _SawdustMotesState();
}

class _SawdustMotesState extends State<SawdustMotes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rnd = Random(9);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    final t = widget.theme ?? WorkshopThemes.all[0];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _MotePainter(_c.value, _rnd, t),
      ),
    );
  }
}

class _MotePainter extends CustomPainter {
  final double t;
  final Random rnd;
  final WorkshopThemeDef theme;
  _MotePainter(this.t, this.rnd, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = theme.lampAmber.withValues(alpha: 0.75);
    for (var i = 0; i < 14; i++) {
      final x = ((rnd.nextDouble() + t * (0.05 + rnd.nextDouble() * 0.1)) % 1) *
          size.width;
      final y = ((rnd.nextDouble() - t * 0.25) % 1).abs() * size.height;
      canvas.drawCircle(Offset(x, y), 1.2 + rnd.nextDouble() * 1.4, p);
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Sawdust particle burst on clear: chips fly off the cleared cells.
// ---------------------------------------------------------------------------
class ClearBurst extends StatefulWidget {
  /// cell index -> chip color.
  final Map<int, Color> cells;
  final double pitch; // board cell pitch in px
  final int burstId;
  final WorkshopThemeDef? theme;
  const ClearBurst({
    super.key,
    required this.cells,
    required this.pitch,
    required this.burstId,
    this.theme,
  });

  @override
  State<ClearBurst> createState() => _ClearBurstState();
}

class _ClearBurstState extends State<ClearBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750))
      ..forward();
  }

  @override
  void didUpdateWidget(covariant ClearBurst old) {
    super.didUpdateWidget(old);
    if (widget.burstId != old.burstId) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cells.isEmpty) return const SizedBox.shrink();
    final t = widget.theme ?? WorkshopThemes.all[0];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _BurstPainter(
          progress: _c.value,
          cells: widget.cells,
          pitch: widget.pitch,
          seed: widget.burstId,
          dust: t.accentLight,
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final Map<int, Color> cells;
  final double pitch;
  final int seed;
  final Color dust;
  _BurstPainter({
    required this.progress,
    required this.cells,
    required this.pitch,
    required this.seed,
    required this.dust,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed * 7919 + 13);
    for (final e in cells.entries) {
      final r = e.key ~/ 8, c = e.key % 8;
      final origin = Offset((c + 0.5) * pitch, (r + 0.5) * pitch);
      // 3 chips per cleared cell.
      for (var k = 0; k < 3; k++) {
        final ang = rnd.nextDouble() * pi * 2;
        final speed = pitch * (0.6 + rnd.nextDouble() * 1.6);
        final dx = cos(ang) * speed * progress;
        final dy = sin(ang) * speed * progress - pitch * 0.9 * progress +
            pitch * 2.2 * progress * progress; // gravity arc
        final pos = origin + Offset(dx, dy);
        final alpha = (1 - progress).clamp(0.0, 1.0);
        final col = (k == 0 ? e.value : dust).withValues(alpha: alpha);
        final rad = pitch * (0.05 + rnd.nextDouble() * 0.07) * (1 - progress * 0.5);
        canvas.drawCircle(pos, rad, Paint()..color = col);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress || old.seed != seed;
}

// ---------------------------------------------------------------------------
// Combo celebration: big wooden luggage tag that slams in and fades.
// ---------------------------------------------------------------------------
class ComboCelebration extends StatefulWidget {
  final int combo;
  final int celebrateId;
  final WorkshopThemeDef? theme;
  const ComboCelebration({
    super.key,
    required this.combo,
    required this.celebrateId,
    this.theme,
  });

  @override
  State<ComboCelebration> createState() => _ComboCelebrationState();
}

class _ComboCelebrationState extends State<ComboCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..forward();
  }

  @override
  void didUpdateWidget(covariant ComboCelebration old) {
    super.didUpdateWidget(old);
    if (widget.celebrateId != old.celebrateId) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo < 2) return const SizedBox.shrink();
    final t = widget.theme ?? WorkshopThemes.all[0];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final v = _c.value;
          final scale = v < 0.25
              ? Curves.easeOutBack.transform(v / 0.25)
              : 1.0;
          final fade = v > 0.7 ? (1 - (v - 0.7) / 0.3) : 1.0;
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.3),
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.comboRed,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.trayFrame, width: 3),
                    boxShadow: Workshop.liftedShadow,
                  ),
                  child: Text(
                    'COMBO ×${widget.combo}',
                    style: Workshop.burned(34, color: t.kraft),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
