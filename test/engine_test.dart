import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockfill/engine.dart';

PieceShape shape(String art) {
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

void main() {
  test('RULES.md T1: basic placement scores cells', () {
    final e = BlockFillEngine(seed: 1);
    e.tray[0] = TrayPiece(shape('####'), 0);
    final res = e.place(0, 0, 0);
    expect(res.ok, true);
    expect(e.score, 4);
    expect(e.tray[0], isNull);
    expect(e.board[0], 0);
  });

  test('RULES.md T2: overlap rejected', () {
    final e = BlockFillEngine(seed: 1);
    e.board[2 * 8 + 2] = 0;
    e.tray[0] = TrayPiece(shape('##\n##'), 0);
    final res = e.place(0, 1, 1);
    expect(res.ok, false);
    expect(e.score, 0);
  });

  test('RULES.md T3: out-of-bounds rejected', () {
    final e = BlockFillEngine(seed: 1);
    e.tray[0] = TrayPiece(shape('#####'), 0);
    final res = e.place(0, 0, 6);
    expect(res.ok, false);
    expect(e.score, 0);
  });

  test('RULES.md T4: row clear = +80 + placement', () {
    final e = BlockFillEngine(seed: 1);
    for (var c = 0; c < 7; c++) {
      e.board[4 * 8 + c] = 0;
    }
    e.tray[0] = TrayPiece(shape('#'), 0);
    final res = e.place(0, 4, 7);
    expect(res.ok, true);
    expect(res.lines, 1);
    expect(res.clearBonus, 80);
    expect(e.score, 1 + 80);
    for (var c = 0; c < 8; c++) {
      expect(e.board[4 * 8 + c], -1);
    }
  });

  test('RULES.md T5/T12: row+column chain = 320, cells cleared once', () {
    final e = BlockFillEngine(seed: 1);
    // Row 2 filled except (2,7); column 7 filled except (2,7).
    for (var c = 0; c < 7; c++) {
      e.board[2 * 8 + c] = 0;
    }
    for (var r = 0; r < 8; r++) {
      if (r != 2) e.board[r * 8 + 7] = 0;
    }
    e.tray[0] = TrayPiece(shape('#'), 0);
    final res = e.place(0, 2, 7);
    expect(res.ok, true);
    expect(res.lines, 2);
    // (8 + 8 cells) x 10 x 2 chain = 320 per RULES.md test 12
    expect(res.clearBonus, 320);
    expect(e.score, 1 + 320);
    // 15 distinct cells emptied
    expect(res.clearedCells.length, 15);
  });

  test('RULES.md T6: 3x3 region clear = +90', () {
    final e = BlockFillEngine(seed: 1);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        e.board[r * 8 + c] = 0;
      }
    }
    e.board[2 * 8 + 2] = -1;
    e.tray[0] = TrayPiece(shape('#'), 0);
    final res = e.place(0, 2, 2);
    expect(res.lines, 1);
    expect(res.clearBonus, 90);
    expect(e.score, 1 + 90);
  });

  test('RULES.md T7: combo increments on consecutive clears, resets', () {
    final e = BlockFillEngine(seed: 1);
    // First clear.
    for (var c = 0; c < 7; c++) {
      e.board[c] = 0;
    }
    e.tray[0] = TrayPiece(shape('#'), 0);
    var res = e.place(0, 0, 7);
    expect(res.combo, 1);
    expect(res.clearBonus, 80); // 80 x 1 chain x 1 combo
    // Second consecutive clear -> combo 2 -> 2x.
    for (var c = 0; c < 7; c++) {
      e.board[8 + c] = 0;
    }
    e.tray[0] = TrayPiece(shape('#'), 0);
    res = e.place(0, 1, 7);
    expect(res.combo, 2);
    expect(res.clearBonus, 160);
    // Non-clearing placement resets combo.
    e.tray[0] = TrayPiece(shape('#'), 0);
    res = e.place(0, 5, 5);
    expect(res.lines, 0);
    expect(e.combo, 0);
  });

  test('RULES.md T8/T11: game over when nothing fits', () {
    final e = BlockFillEngine(seed: 1);
    // Fill everything except scattered single cells that can't host a 3x3.
    for (var i = 0; i < 64; i++) {
      e.board[i] = 0;
    }
    e.board[0] = -1;
    e.board[63] = -1;
    e.tray[0] = TrayPiece(shape('###\n###\n###'), 0);
    e.tray[1] = null;
    e.tray[2] = null;
    expect(e.isGameOver, true);
  });

  test('RULES.md T9: rotation fit keeps game alive', () {
    final e = BlockFillEngine(seed: 1);
    for (var i = 0; i < 64; i++) {
      e.board[i] = 0;
    }
    for (var r = 0; r < 4; r++) {
      e.board[r * 8 + 3] = -1; // vertical run of 4
    }
    e.tray[0] = TrayPiece(shape('####'), 0); // horizontal bar
    e.tray[1] = null;
    e.tray[2] = null;
    expect(e.isGameOver, false); // rotated (vertical) it fits
  });

  test('RULES.md T10: tray redeal after 3 placements', () {
    final e = BlockFillEngine(seed: 1);
    e.tray[0] = TrayPiece(shape('#'), 0);
    e.tray[1] = TrayPiece(shape('#'), 0);
    e.tray[2] = TrayPiece(shape('#'), 0);
    e.place(0, 0, 0);
    e.place(1, 0, 1);
    e.place(2, 0, 2);
    expect(e.trayEmpty, true);
    e.dealTray();
    expect(e.tray.where((t) => t != null).length, 3);
  });

  test('RULES.md T13: level up at 500 points', () {
    final e = BlockFillEngine(seed: 1);
    expect(e.level, 1);
    e.score = 500;
    expect(e.level, 2);
    e.score = 1200;
    expect(e.level, 3);
  });

  test('rotation is 90 degrees clockwise', () {
    final s = shape('##\n#.');
    final r = s.rotated;
    expect(r.w, s.h);
    expect(r.h, s.w);
    expect(r.cells.length, s.cells.length);
  });

  test('hint returns a legal placement on open board', () {
    final e = BlockFillEngine(seed: 42);
    e.reset();
    final h = e.findHint();
    expect(h, isNotNull);
    var s = e.tray[h!.trayIndex]!.shape;
    for (var k = 0; k < h.rotations; k++) {
      s = s.rotated;
    }
    expect(e.canPlace(s, h.row, h.col), true);
  });

  test('daily seed is deterministic per date', () {
    final a = BlockFillEngine.dailySeed(DateTime(2026, 10, 9));
    final b = BlockFillEngine.dailySeed(DateTime(2026, 10, 9));
    final c = BlockFillEngine.dailySeed(DateTime(2026, 10, 10));
    expect(a, b);
    expect(a == c, false);
  });
}
