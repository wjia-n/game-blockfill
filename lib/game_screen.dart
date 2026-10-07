import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Block Fill — 8x8 board, 3 pieces at a time. Fill rows/columns to blast them.
class BlockFillScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const BlockFillScreen({super.key, required this.players, required this.callbacks});
  @override
  State<BlockFillScreen> createState() => _BlockFillScreenState();
}

const _shapeArt = [
  '#', '##', '#\n#', '###', '#\n#\n#', '####', '#\n#\n#\n#',
  '##\n##', '###\n###', '##\n##\n##', '###\n###\n###',
  '#.\n##', '.#\n##', '##\n#.', '##\n#.',
  '#..\n###', '..#\n###', '###\n#..', '###\n..#',
  '.#.\n###', '#.\n#.\n##', '.#\n.#\n##', '.#.\n###\n.#.',
];

class _Piece {
  final List<Point<int>> cells;
  final int w, h, tint;
  _Piece(this.cells, this.w, this.h, this.tint);
}

_Piece _parse(String art, int tint, Random rnd) {
  final rows = art.split('\n');
  var cells = <Point<int>>[];
  var maxC = 0;
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      if (rows[r][c] == '#') {
        cells.add(Point(c, r));
        maxC = max(maxC, c);
      }
    }
  }
  var p = _Piece(cells, maxC + 1, rows.length, tint);
  for (var k = 0, n = rnd.nextInt(4); k < n; k++) {
    p = _Piece([for (final pt in p.cells) Point(p.h - 1 - pt.y, pt.x)], p.h, p.w, tint);
  }
  return p;
}

class _BlockFillScreenState extends State<BlockFillScreen> {
  final board = List.filled(64, false);
  final boardTint = List.filled(64, -1);
  final tray = List<_Piece?>.filled(3, null);
  int selPiece = -1, score = 0, best = 0, animId = 0;
  Set<int> clearing = {}, lastPlaced = {};
  bool over = false;
  String hintMsg = 'Tap a piece, then tap the board 👇';
  final rnd = Random();

  Player get me => widget.players[0];

  @override
  void initState() {
    super.initState();
    _loadBest();
    _dealTray();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => best = p.getInt('blockfill_best') ?? 0);
  }

  Future<void> _saveBest() async {
    if (score <= best) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt('blockfill_best', score);
    if (mounted) setState(() => best = score);
  }

  void _dealTray() {
    for (var i = 0; i < 3; i++) {
      tray[i] = _parse(_shapeArt[rnd.nextInt(_shapeArt.length)], rnd.nextInt(3), rnd);
    }
  }

  void _newGame() {
    Sfx.click();
    setState(() {
      board.fillRange(0, 64, false);
      boardTint.fillRange(0, 64, -1);
      score = 0;
      me.score = 0;
      over = false;
      selPiece = -1;
      clearing = {};
      lastPlaced = {};
      hintMsg = 'Tap a piece, then tap the board 👇';
      _dealTray();
      animId++;
    });
    widget.callbacks.refreshHud();
  }

  bool _canPlace(_Piece p, int r, int c) {
    for (final pt in p.cells) {
      final rr = r + pt.y, cc = c + pt.x;
      if (rr < 0 || rr > 7 || cc < 0 || cc > 7 || board[rr * 8 + cc]) return false;
    }
    return true;
  }

  bool _fitsAnywhere(_Piece p) {
    for (var r = 0; r <= 8 - p.h; r++) {
      for (var c = 0; c <= 8 - p.w; c++) {
        if (_canPlace(p, r, c)) return true;
      }
    }
    return false;
  }

  void _tapTray(int i) {
    if (over || tray[i] == null || clearing.isNotEmpty) return;
    Sfx.tap();
    setState(() => selPiece = (selPiece == i) ? -1 : i);
  }

  void _tapBoard(int r, int c) {
    if (over || selPiece < 0 || tray[selPiece] == null || clearing.isNotEmpty) return;
    final p = tray[selPiece]!;
    if (!_canPlace(p, r, c)) {
      Sfx.lose();
      setState(() => hintMsg = 'Nope, doesn\'t fit there! Try another spot 🙈');
      return;
    }
    final placed = <int>{};
    for (final pt in p.cells) {
      final i = (r + pt.y) * 8 + (c + pt.x);
      board[i] = true;
      boardTint[i] = p.tint;
      placed.add(i);
    }
    setState(() {
      score += p.cells.length;
      me.score = score;
      tray[selPiece] = null;
      selPiece = -1;
      lastPlaced = placed;
      animId++;
      hintMsg = 'Nice fit! 🧱';
    });
    widget.callbacks.refreshHud();
    Sfx.move();
    _checkClears();
    if (tray.every((t) => t == null)) {
      setState(_dealTray);
    }
    if (clearing.isEmpty) _checkGameOver();
  }

  void _checkClears() {
    final full = <int>{};
    var lines = 0;
    for (var r = 0; r < 8; r++) {
      if ([for (var c = 0; c < 8; c++) board[r * 8 + c]].every((b) => b)) {
        lines++;
        for (var c = 0; c < 8; c++) { full.add(r * 8 + c); }
      }
    }
    for (var c = 0; c < 8; c++) {
      if ([for (var r = 0; r < 8; r++) board[r * 8 + c]].every((b) => b)) {
        lines++;
        for (var r = 0; r < 8; r++) { full.add(r * 8 + c); }
      }
    }
    if (lines == 0) return;
    final bonus = lines * 10 + (lines > 1 ? (lines - 1) * 25 : 0);
    setState(() {
      score += bonus;
      me.score = score;
      clearing = full;
      hintMsg = lines > 1 ? 'MEGA CLEAR ×$lines! +$bonus 🎆' : 'Line clear! +$bonus ✨';
    });
    widget.callbacks.refreshHud();
    Sfx.win();
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() {
        for (final i in full) {
          board[i] = false;
          boardTint[i] = -1;
        }
        clearing = {};
      });
      _checkGameOver();
    });
  }

  void _checkGameOver() {
    for (final p in tray) {
      if (p != null && _fitsAnywhere(p)) return;
    }
    over = true;
    Sfx.lose();
    _saveBest();
    widget.callbacks.finish(
      headline: 'No more fits — $score points! 🧱',
      subline: score >= best && score > 0
          ? 'NEW BEST! You\'re a block-fitting wizard! 🏆'
          : 'Best: $best. The blocks believe in you. Try again!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final palette = [t.primary, t.secondary, t.accent];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _statBox(t, 'SCORE', '$score'),
          _statBox(t, 'BEST', '$best'),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: t.surface, borderRadius: t.radius),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
                  itemCount: 64,
                  itemBuilder: (_, i) => _cell(i, t, palette),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(hintMsg, style: TextStyle(color: t.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (var i = 0; i < 3; i++) _trayPiece(i, t, palette)],
          ),
        ),
        const SizedBox(height: 8),
        WajihaButton(label: 'New Game', emoji: '🔄', onTap: _newGame),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _statBox(GameTheme t, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(gradient: t.headerGradient, borderRadius: t.radius),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _cell(int i, GameTheme t, List<Color> palette) {
    final filled = board[i];
    final flash = clearing.contains(i);
    final pop = lastPlaced.contains(i);
    final base = filled
        ? palette[boardTint[i].clamp(0, 2)]
        : t.background.withValues(alpha: 0.55);
    return GestureDetector(
      onTap: () => _tapBoard(i ~/ 8, i % 8),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$animId-$i'),
        tween: Tween(begin: pop ? 0.3 : 1.0, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        builder: (_, s, child) => Transform.scale(
          scale: s,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: flash ? Colors.white : base,
              borderRadius: BorderRadius.circular(6),
              boxShadow: filled && !flash
                  ? [BoxShadow(color: base.withValues(alpha: 0.45), blurRadius: 5, offset: const Offset(0, 2))]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _trayPiece(int i, GameTheme t, List<Color> palette) {
    final p = tray[i];
    final selected = selPiece == i;
    return GestureDetector(
      onTap: () => _tapTray(i),
      child: AnimatedScale(
        scale: selected ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          width: 92,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: t.radius,
            border: Border.all(
                color: selected ? t.primary : t.primary.withValues(alpha: 0.25),
                width: selected ? 2.5 : 1.2),
          ),
          alignment: Alignment.center,
          child: p == null
              ? Text('✅', style: TextStyle(fontSize: 26, color: t.muted))
              : _pieceArt(p, palette),
        ),
      ),
    );
  }

  Widget _pieceArt(_Piece p, List<Color> palette) {
    final color = palette[p.tint.clamp(0, 2)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < p.h; r++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var c = 0; c < p.w; c++)
              Container(
                width: 15,
                height: 15,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: p.cells.any((pt) => pt.x == c && pt.y == r)
                      ? color
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
      ],
    );
  }
}
