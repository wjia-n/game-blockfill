import 'dart:math';

/// Block Fill engine — deterministic game logic per RULES.md.
/// 8x8 board, tray of 3 polyomino pieces, row/column/3x3-region clears,
/// chain + combo scoring, craftsman levels, hint bot, daily seed.
class PieceShape {
  final List<Point<int>> cells;
  final int w;
  final int h;
  const PieceShape(this.cells, this.w, this.h);

  int get size => cells.length;

  /// 90° clockwise rotation.
  PieceShape get rotated {
    final rc = [for (final p in cells) Point<int>(h - 1 - p.y, p.x)];
    return PieceShape(rc, h, w);
  }

  @override
  String toString() => 'PieceShape(${w}x$h, ${cells.length} cells)';
}

PieceShape _shape(String art) {
  final rows = art.split('\n');
  final cells = <Point<int>>[];
  var maxC = 0;
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      if (rows[r][c] == '#') {
        cells.add(Point(c, r));
        if (c > maxC) maxC = c;
      }
    }
  }
  return PieceShape(cells, maxC + 1, rows.length);
}

/// All piece shapes: polyominoes of 1–9 cells, rectangles ≤ 3x3, bars ≤ 5.
final List<PieceShape> allShapes = [
  // monomino
  '#',
  // dominoes
  '##', '#\n#',
  // trominoes
  '###', '#\n#\n#', '#.\n##', '.#\n##', '##\n#.', '##\n.#',
  // tetrominoes
  '####', '#\n#\n#\n#', '##\n##',
  '#..\n###', '..#\n###', '###\n#..', '###\n..#',
  '.#.\n###', '###\n.#.', '.##\n##.', '##.\n.##',
  // pentominoes
  '#####', '#\n#\n#\n#\n#', '#\n#\n#\n##', '##\n#.\n#.\n#.',
  '#.#\n###', '###\n#.#', '#..\n#..\n###', '###\n..#\n..#',
  '.#.\n###\n.#.', '.#.\n###\n.#.',
  '##.\n##.\n.#.', '.##\n.##\n..#',
  // rectangles
  '###\n###', '##\n##\n##', '###\n###\n###',
].map(_shape).toList();

/// A piece sitting in the tray (current orientation + wood stain index).
class TrayPiece {
  PieceShape shape;
  final int stain;
  TrayPiece(this.shape, this.stain);

  void rotate() => shape = shape.rotated;
}

/// Result of a placement attempt.
class PlaceResult {
  final bool ok;
  final int placementPoints;
  final int clearBonus;
  final int lines;
  final int combo;
  final Set<int> clearedCells;

  /// Stain index per cleared cell (for the sweep animation).
  final Map<int, int> clearedStains;
  const PlaceResult({
    required this.ok,
    this.placementPoints = 0,
    this.clearBonus = 0,
    this.lines = 0,
    this.combo = 0,
    this.clearedCells = const {},
    this.clearedStains = const {},
  });
}

/// A hint suggestion: which tray piece, rotation, and board position.
class Hint {
  final int trayIndex;
  final int rotations;
  final int row;
  final int col;
  const Hint(this.trayIndex, this.rotations, this.row, this.col);
}

class BlockFillEngine {
  static const int size = 8;

  /// -1 = empty, otherwise wood-stain index of the occupying block.
  final List<int> board = List.filled(size * size, -1);
  final List<TrayPiece?> tray = List.filled(3, null);

  int score = 0;
  int combo = 0;
  int piecesPlaced = 0;
  int linesCleared = 0;
  int bestCombo = 0;
  bool _prevCleared = false;

  final Random rng;

  BlockFillEngine({int? seed}) : rng = Random(seed);

  /// Craftsman level: every 500 points advances a rank (RULES.md §7).
  int get level => score ~/ 500 + 1;

  /// Craftsman title milestones (RULES.md §9).
  static String titleFor(int score) {
    if (score >= 40000) return 'Grandmaster of the Bench';
    if (score >= 15000) return 'Master Carpenter';
    if (score >= 5000) return 'Journeyman';
    if (score >= 1000) return 'Apprentice';
    return 'Workshop Hand';
  }

  int get emptyCount => board.where((v) => v < 0).length;

  void reset() {
    board.fillRange(0, board.length, -1);
    for (var i = 0; i < 3; i++) {
      tray[i] = null;
    }
    score = 0;
    combo = 0;
    piecesPlaced = 0;
    linesCleared = 0;
    bestCombo = 0;
    _prevCleared = false;
    dealTray();
  }

  // --- piece generation ---------------------------------------------------

  TrayPiece _randomPiece() {
    final emptyFrac = emptyCount / (size * size);
    // Weight pools: crowded boards want small pieces, open boards + higher
    // levels want larger pieces (RULES.md §2, §7).
    final largeW = emptyFrac * (1 + 0.2 * (level - 1));
    final smallW = (1 - emptyFrac) * 1.2 + 0.3;
    const medW = 1.0;
    final small = <PieceShape>[];
    final med = <PieceShape>[];
    final large = <PieceShape>[];
    for (final s in allShapes) {
      if (s.size <= 3) {
        small.add(s);
      } else if (s.size <= 5) {
        med.add(s);
      } else {
        large.add(s);
      }
    }
    final roll = rng.nextDouble() * (smallW + medW + largeW);
    final pool = roll < smallW ? small : (roll < smallW + medW ? med : large);
    var shape = pool[rng.nextInt(pool.length)];
    for (var k = 0, n = rng.nextInt(4); k < n; k++) {
      shape = shape.rotated;
    }
    return TrayPiece(shape, rng.nextInt(5));
  }

  /// Deal a fresh tray of 3. Grace rule (RULES.md §7): the new tray is
  /// guaranteed to contain at least one fitting piece IF any legal
  /// placement exists on the board at all.
  void dealTray() {
    for (var i = 0; i < 3; i++) {
      tray[i] = _randomPiece();
    }
    if (!boardHasAnyPlacement()) return; // game will end; no deal helps
    if (trayFitsAnywhere()) return;
    // Retry with smaller-biased pieces.
    for (var attempt = 0; attempt < 60 && !trayFitsAnywhere(); attempt++) {
      tray[rng.nextInt(3)] = _randomPiece();
    }
    if (!trayFitsAnywhere()) {
      // Forced grace: find any shape that fits and slot it in.
      final forced = _findFittingShape();
      if (forced != null) tray[rng.nextInt(3)] = TrayPiece(forced, rng.nextInt(5));
    }
  }

  PieceShape? _findFittingShape() {
    for (final s in allShapes) {
      var shape = s;
      for (var k = 0; k < 4; k++) {
        for (var r = 0; r <= size - shape.h; r++) {
          for (var c = 0; c <= size - shape.w; c++) {
            if (canPlace(shape, r, c)) return shape;
          }
        }
        shape = shape.rotated;
      }
    }
    return null;
  }

  // --- placement ----------------------------------------------------------

  bool canPlace(PieceShape s, int r, int c) {
    for (final p in s.cells) {
      final rr = r + p.y, cc = c + p.x;
      if (rr < 0 || rr >= size || cc < 0 || cc >= size) return false;
      if (board[rr * size + cc] >= 0) return false;
    }
    return true;
  }

  bool pieceFitsAnywhere(PieceShape s) {
    var shape = s;
    for (var k = 0; k < 4; k++) {
      for (var r = 0; r <= size - shape.h; r++) {
        for (var c = 0; c <= size - shape.w; c++) {
          if (canPlace(shape, r, c)) return true;
        }
      }
      shape = shape.rotated;
    }
    return false;
  }

  /// True when at least one tray piece fits somewhere (all rotations).
  bool trayFitsAnywhere() {
    for (final t in tray) {
      if (t != null && pieceFitsAnywhere(t.shape)) return true;
    }
    return false;
  }

  /// True when ANY shape in the library fits the board (grace-rule check).
  bool boardHasAnyPlacement() => _findFittingShape() != null;

  bool get trayEmpty => tray.every((t) => t == null);

  /// Place tray[trayIndex] at board (r, c). Returns the scoring outcome.
  PlaceResult place(int trayIndex, int r, int c) {
    final t = (trayIndex >= 0 && trayIndex < 3) ? tray[trayIndex] : null;
    if (t == null || !canPlace(t.shape, r, c)) {
      return const PlaceResult(ok: false);
    }
    final placed = <int>[];
    for (final p in t.shape.cells) {
      final i = (r + p.y) * size + (c + p.x);
      board[i] = t.stain;
      placed.add(i);
    }
    tray[trayIndex] = null;
    final placementPoints = placed.length;
    score += placementPoints;
    piecesPlaced++;

    final clear = _resolveClears();
    final cleared = clear.cleared;
    var bonus = 0;
    if (clear.lines > 0) {
      combo = _prevCleared ? combo + 1 : 1;
      if (combo > bestCombo) bestCombo = combo;
      // RULES.md §8: 10 pts per cell of each cleared line × chain (N lines)
      // × combo (capped at 5).
      bonus = 10 * clear.lineCells * clear.lines * min(combo, 5);
      score += bonus;
      linesCleared += clear.lines;
      _prevCleared = true;
    } else {
      combo = 0;
      _prevCleared = false;
    }
    return PlaceResult(
      ok: true,
      placementPoints: placementPoints,
      clearBonus: bonus,
      lines: clear.lines,
      combo: combo,
      clearedCells: cleared,
      clearedStains: clear.stains,
    );
  }

  /// Game over when no tray piece fits anywhere (RULES.md §10).
  bool get isGameOver => !trayEmpty && !trayFitsAnywhere();

  // --- clear resolution ---------------------------------------------------

  _Clear _resolveClears() {
    var lines = 0;
    var lineCells = 0;
    final cleared = <int>{};
    final stains = <int, int>{};
    // (1) full rows
    for (var r = 0; r < size; r++) {
      var full = true;
      for (var c = 0; c < size; c++) {
        if (board[r * size + c] < 0) {
          full = false;
          break;
        }
      }
      if (full) {
        lines++;
        lineCells += size;
        for (var c = 0; c < size; c++) {
          cleared.add(r * size + c);
        }
      }
    }
    // (2) full columns
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (board[r * size + c] < 0) {
          full = false;
          break;
        }
      }
      if (full) {
        lines++;
        lineCells += size;
        for (var r = 0; r < size; r++) {
          cleared.add(r * size + c);
        }
      }
    }
    // (3) full 3x3 regions. An 8x8 board holds four complete 3x3 blocks
    // (rows/cols 0..5); cells in rows 6-7 / cols 6-7 belong to no region.
    for (var br = 0; br < 2; br++) {
      for (var bc = 0; bc < 2; bc++) {
        var full = true;
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            if (board[r * size + c] < 0) {
              full = false;
              break;
            }
          }
          if (!full) break;
        }
        if (full) {
          lines++;
          lineCells += 9;
          for (var r = br * 3; r < br * 3 + 3; r++) {
            for (var c = bc * 3; c < bc * 3 + 3; c++) {
              cleared.add(r * size + c);
            }
          }
        }
      }
    }
    for (final i in cleared) {
      stains[i] = board[i];
      board[i] = -1;
    }
    return _Clear(lines, lineCells, cleared, stains);
  }

  /// Lines that WOULD complete if [shape] were placed at (r, c).
  /// Used for the warm "about-to-clear" preview.
  Set<int> wouldClear(PieceShape s, int r, int c) {
    if (!canPlace(s, r, c)) return {};
    final sim = List<int>.from(board);
    for (final p in s.cells) {
      sim[(r + p.y) * size + (c + p.x)] = 0;
    }
    return _simClear(sim).cleared;
  }

  // --- hint bot (RULES.md §11) --------------------------------------------

  Hint? findHint() {
    Hint? best;
    var bestScore = double.negativeInfinity;
    for (var ti = 0; ti < 3; ti++) {
      final t = tray[ti];
      if (t == null) continue;
      var shape = t.shape;
      for (var rot = 0; rot < 4; rot++) {
        for (var r = 0; r <= size - shape.h; r++) {
          for (var c = 0; c <= size - shape.w; c++) {
            if (!canPlace(shape, r, c)) continue;
            final s = _scoreCandidate(shape, r, c);
            if (s > bestScore) {
              bestScore = s;
              best = Hint(ti, rot, r, c);
            }
          }
        }
        shape = shape.rotated;
      }
    }
    return best;
  }

  double _scoreCandidate(PieceShape s, int r, int c) {
    // Simulate placement on a copy.
    final sim = List<int>.from(board);
    for (final p in s.cells) {
      sim[(r + p.y) * size + (c + p.x)] = 0;
    }
    // 1. Clear value (weight 10).
    final clear = _simClear(sim);
    var value = 0.0;
    if (clear.lines > 0) {
      value += 10 * clear.lineCells * clear.lines * min(combo + 1, 5) * 10;
    }
    // Apply the clear to the sim for mobility analysis.
    for (final i in clear.cleared) {
      sim[i] = -1;
    }
    // 2. Future mobility (weight 4): empty cells minus pocket penalty.
    final emptyRegions = _emptyRegions(sim);
    var emptyTotal = 0;
    var pocketPenalty = 0;
    for (final region in emptyRegions) {
      emptyTotal += region.length;
      if (region.length < 3) pocketPenalty += (3 - region.length) * 12;
    }
    value += 4 * (emptyTotal - pocketPenalty);
    // 3. Surface smoothness (weight 2): penalize single-cell notches.
    var notches = 0;
    for (var i = 0; i < 64; i++) {
      if (sim[i] >= 0) continue;
      final rr = i ~/ 8, cc = i % 8;
      var filledNb = 0;
      if (rr > 0 && sim[i - 8] >= 0) filledNb++;
      if (rr < 7 && sim[i + 8] >= 0) filledNb++;
      if (cc > 0 && sim[i - 1] >= 0) filledNb++;
      if (cc < 7 && sim[i + 1] >= 0) filledNb++;
      if (filledNb >= 3) notches++;
    }
    value -= 2 * notches * 6;
    // 4. Region completion bias (weight 3): cells in nearly-full lines.
    var nearFull = 0;
    for (final p in s.cells) {
      final rr = r + p.y, cc = c + p.x;
      var rowF = 0, colF = 0, regF = 0;
      for (var k = 0; k < 8; k++) {
        if (board[rr * 8 + k] >= 0) rowF++;
        if (board[k * 8 + cc] >= 0) colF++;
      }
      if (rr < 6 && cc < 6) {
        final br = (rr ~/ 3) * 3, bc = (cc ~/ 3) * 3;
        for (var a = br; a < br + 3; a++) {
          for (var b2 = bc; b2 < bc + 3; b2++) {
            if (board[a * 8 + b2] >= 0) regF++;
          }
        }
      }
      if (rowF >= 6 || colF >= 6 || regF >= 7) nearFull++;
    }
    value += 3 * nearFull * 8;
    // 5. Piece conservation.
    if (clear.lines > 0) {
      value += (10 - s.size) * 6; // smallest piece that triggers a clear
    } else {
      value += s.size * 4; // largest piece first when no clear available
    }
    // 6. Corner anchoring tie-break.
    final cr = r + s.h / 2 - 3.5, cc2 = c + s.w / 2 - 3.5;
    value -= (cr.abs() + cc2.abs()) * 0.5;
    return value;
  }

  _Clear _simClear(List<int> sim) {
    var lines = 0;
    var lineCells = 0;
    final cleared = <int>{};
    for (var r = 0; r < size; r++) {
      var full = true;
      for (var c = 0; c < size; c++) {
        if (sim[r * size + c] < 0) {
          full = false;
          break;
        }
      }
      if (full) {
        lines++;
        lineCells += size;
        for (var c = 0; c < size; c++) {
          cleared.add(r * size + c);
        }
      }
    }
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (sim[r * size + c] < 0) {
          full = false;
          break;
        }
      }
      if (full) {
        lines++;
        lineCells += size;
        for (var r = 0; r < size; r++) {
          cleared.add(r * size + c);
        }
      }
    }
    for (var br = 0; br < 2; br++) {
      for (var bc = 0; bc < 2; bc++) {
        var full = true;
        for (var r = br * 3; r < br * 3 + 3 && full; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            if (sim[r * size + c] < 0) {
              full = false;
              break;
            }
          }
        }
        if (full) {
          lines++;
          lineCells += 9;
          for (var r = br * 3; r < br * 3 + 3; r++) {
            for (var c = bc * 3; c < bc * 3 + 3; c++) {
              cleared.add(r * size + c);
            }
          }
        }
      }
    }
    return _Clear(lines, lineCells, cleared);
  }

  List<List<int>> _emptyRegions(List<int> sim) {
    final seen = List.filled(64, false);
    final regions = <List<int>>[];
    for (var i = 0; i < 64; i++) {
      if (sim[i] >= 0 || seen[i]) continue;
      final region = <int>[];
      final stack = [i];
      seen[i] = true;
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        region.add(cur);
        final rr = cur ~/ 8, cc = cur % 8;
        for (final nb in [
          if (rr > 0) cur - 8,
          if (rr < 7) cur + 8,
          if (cc > 0) cur - 1,
          if (cc < 7) cur + 1,
        ]) {
          if (sim[nb] < 0 && !seen[nb]) {
            seen[nb] = true;
            stack.add(nb);
          }
        }
      }
      regions.add(region);
    }
    return regions;
  }

  /// Deterministic daily seed from a calendar date (RULES.md §12).
  static int dailySeed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}

class _Clear {
  final int lines;
  final int lineCells;
  final Set<int> cleared;
  final Map<int, int> stains;
  _Clear(this.lines, this.lineCells, this.cleared, [this.stains = const {}]);
}
