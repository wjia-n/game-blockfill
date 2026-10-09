import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio.dart';
import 'engine.dart';
import 'scores.dart';

/// UI-facing state for a Block Fill session. Wraps [BlockFillEngine] with
/// selection, drag, ghost preview, clear animations, pause, and game over.
class GameController extends ChangeNotifier {
  late BlockFillEngine engine;
  final bool daily;
  final String? dailyDate;

  int selected = -1;

  // Drag state (global pointer position + hovered cell).
  bool dragging = false;
  int dragR = -1, dragC = -1;
  double dragX = 0, dragY = 0;

  // Ghost preview for the currently positioned piece.
  Set<int> ghostCells = {};
  Set<int> aboutToClear = {};

  // Sweep animation: cleared cells with their stains.
  Map<int, int> sweepAnim = {};
  int sweepId = 0;

  // Floating score popup.
  String? popupText;
  int popupId = 0;

  bool paused = false;
  bool gameOver = false;
  bool newBest = false;
  bool resolving = false;

  String hintMsg = 'Pick up a block, set it on the bench';
  Hint? hint;
  bool levelUpFlash = false;

  Timer? _popupTimer;

  GameController({this.daily = false, this.dailyDate}) {
    engine = BlockFillEngine(
        seed: daily && dailyDate != null
            ? BlockFillEngine.dailySeed(_parseDate(dailyDate!))
            : null);
    newGame();
  }

  static DateTime _parseDate(String d) {
    final p = d.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  int get score => engine.score;
  int get best => daily
      ? ScoreStore.I.dailyBestFor(dailyDate ?? '')
      : ScoreStore.I.bestClassic;

  void newGame() {
    engine.reset();
    selected = -1;
    dragging = false;
    ghostCells = {};
    aboutToClear = {};
    sweepAnim = {};
    popupText = null;
    paused = false;
    gameOver = false;
    newBest = false;
    resolving = false;
    hint = null;
    hintMsg = 'Pick up a block, set it on the bench';
    notifyListeners();
    Sound.I.gameStart();
  }

  void setHint(String m) {
    hintMsg = m;
    notifyListeners();
  }

  void _bump() {
    if (ScoreStore.I.hapticsOn) {
      HapticFeedback.lightImpact();
    }
  }

  // --- selection ----------------------------------------------------------

  void selectPiece(int i) {
    if (gameOver || paused || resolving) return;
    if (engine.tray[i] == null) return;
    _bump();
    Sound.I.click();
    selected = (selected == i) ? -1 : i;
    hint = null;
    notifyListeners();
  }

  void rotateSelected() {
    if (gameOver || paused || resolving) return;
    final t = selected >= 0 ? engine.tray[selected] : null;
    if (t == null) return;
    _bump();
    Sound.I.rotate();
    t.rotate();
    _updateGhost(dragR, dragC);
    notifyListeners();
  }

  // --- drag ---------------------------------------------------------------

  void beginDrag(int i, double x, double y) {
    if (gameOver || paused || resolving) return;
    if (engine.tray[i] == null) return;
    _bump();
    selected = i;
    dragging = true;
    dragX = x;
    dragY = y;
    dragR = -1;
    dragC = -1;
    hint = null;
    notifyListeners();
  }

  void updateDrag(double x, double y, int r, int c) {
    if (!dragging) return;
    dragX = x;
    dragY = y;
    if (r != dragR || c != dragC) {
      dragR = r;
      dragC = c;
      _updateGhost(r, c);
    }
    notifyListeners();
  }

  void cancelDrag() {
    if (!dragging) return;
    dragging = false;
    dragR = -1;
    dragC = -1;
    ghostCells = {};
    aboutToClear = {};
    notifyListeners();
  }

  void endDrag() {
    if (!dragging) return;
    final r = dragR, c = dragC;
    dragging = false;
    if (r >= 0 && c >= 0 && selected >= 0) {
      tryPlace(r, c);
    } else {
      ghostCells = {};
      aboutToClear = {};
      notifyListeners();
    }
  }

  void _updateGhost(int r, int c) {
    ghostCells = {};
    aboutToClear = {};
    final t = selected >= 0 ? engine.tray[selected] : null;
    if (t == null || r < 0 || c < 0) return;
    if (!engine.canPlace(t.shape, r, c)) return;
    for (final p in t.shape.cells) {
      ghostCells.add((r + p.y) * 8 + (c + p.x));
    }
    aboutToClear = engine.wouldClear(t.shape, r, c);
  }

  // --- tap-to-place --------------------------------------------------------

  void tapBoard(int r, int c) {
    if (gameOver || paused || resolving || dragging) return;
    if (selected < 0 || engine.tray[selected] == null) {
      hintMsg = 'Pick up a block first';
      notifyListeners();
      return;
    }
    tryPlace(r, c);
  }

  // --- placement ----------------------------------------------------------

  Future<void> tryPlace(int r, int c) async {
    if (resolving || gameOver || paused) return;
    final t = selected >= 0 ? engine.tray[selected] : null;
    if (t == null) return;
    if (!engine.canPlace(t.shape, r, c)) {
      Sound.I.invalid();
      _bump();
      hintMsg = 'It won\'t fit there — try another spot';
      notifyListeners();
      return;
    }
    resolving = true;
    final placedIndex = selected;
    selected = -1;
    dragging = false;
    ghostCells = {};
    aboutToClear = {};
    hint = null;

    final res = engine.place(placedIndex, r, c);
    final prevLevel = engine.level;
    notifyListeners();

    _bump();
    await Sound.I.place();

    if (res.lines > 0) {
      // Sweep animation: show the cleared blocks briefly, then they vanish.
      sweepAnim = Map<int, int>.from(res.clearedStains);
      sweepId++;
      notifyListeners();
      await Sound.I.clear();
      if (res.combo >= 2) {
        await Sound.I.combo();
        _popup('COMBO ×${res.combo}  +${res.clearBonus}');
      } else if (res.lines > 1) {
        _popup('${res.lines} LINES  +${res.clearBonus}');
      } else {
        _popup('+${res.clearBonus}');
      }
      hintMsg = res.combo >= 2
          ? 'Beautiful joinery! Combo ×${res.combo}'
          : 'Clean sweep! +${res.clearBonus}';
      await Future<void>.delayed(const Duration(milliseconds: 420));
      sweepAnim = {};
      notifyListeners();
    } else {
      hintMsg = _encouragements[engine.piecesPlaced % _encouragements.length];
      notifyListeners();
    }

    if (engine.level > prevLevel) {
      levelUpFlash = true;
      notifyListeners();
      _popup('CRAFTSMAN LEVEL ${engine.level}');
      await Future<void>.delayed(const Duration(milliseconds: 900));
      levelUpFlash = false;
      notifyListeners();
    }

    if (engine.trayEmpty && !engine.isGameOver) {
      engine.dealTray();
      notifyListeners();
    }

    resolving = false;
    if (engine.isGameOver) {
      await _finishGame();
    } else {
      notifyListeners();
    }
  }

  Future<void> _finishGame() async {
    gameOver = true;
    if (daily && dailyDate != null) {
      newBest = await ScoreStore.I.recordDaily(dailyDate!, engine.score);
    } else {
      newBest = await ScoreStore.I.recordClassic(engine.score);
    }
    notifyListeners();
    if (newBest) {
      await Sound.I.newBest();
    } else {
      await Sound.I.gameOver();
    }
  }

  void _popup(String text) {
    popupText = text;
    popupId++;
    notifyListeners();
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(milliseconds: 1100), () {
      popupText = null;
      notifyListeners();
    });
  }

  // --- hint ----------------------------------------------------------------

  void showHint() {
    if (gameOver || paused || resolving) return;
    final h = engine.findHint();
    if (h == null) return;
    Sound.I.hint();
    _bump();
    hint = h;
    selected = h.trayIndex;
    final t = engine.tray[h.trayIndex]!;
    for (var k = 0; k < h.rotations; k++) {
      t.rotate();
    }
    ghostCells = {};
    for (final p in t.shape.cells) {
      ghostCells.add((h.row + p.y) * 8 + (h.col + p.x));
    }
    aboutToClear = engine.wouldClear(t.shape, h.row, h.col);
    hintMsg = 'The master suggests this joint — tap the glowing spot';
    notifyListeners();
  }

  // --- pause ---------------------------------------------------------------

  void setPaused(bool v) {
    if (gameOver) return;
    if (v) cancelDrag();
    paused = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _popupTimer?.cancel();
    super.dispose();
  }

  static const _encouragements = [
    'Snug fit. The bench approves.',
    'Nice joint — keep building.',
    'Steady hands, sharp chisel.',
    'That block found its home.',
    'Measure twice, place once.',
  ];
}
