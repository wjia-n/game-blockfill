import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'engine.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/workshop_themes.dart';

/// UI-facing state for a Block Fill session. Wraps [BlockFillEngine] with
/// selection, drag, ghost preview, clear animations, particles, pause, modes,
/// and game over.
///
/// Watchdog (exemplar pattern): a 1-second timer owns the blitz countdown
/// via [BlockFillEngine.tick], validates engine invariants, and recovers a
/// placement op that stays unresolved too long. The engine owns ALL game
/// state; this class only mirrors it for the UI. Stuck states are impossible
/// by construction: [tryPlace] always settles in try/finally.
class GameController extends ChangeNotifier {
  late BlockFillEngine engine;
  final GameMode mode;
  final String? dailyDate;
  final WorkshopAudio audio;
  final BlockFillSettings settings;

  int selected = -1;

  // Drag state (global pointer position + hovered cell).
  bool dragging = false;
  int dragR = -1, dragC = -1;
  double dragX = 0, dragY = 0;

  // Ghost preview for the currently positioned piece.
  Set<int> ghostCells = {};
  Set<int> aboutToClear = {};

  // Sweep animation: cleared cells with their block-style indices.
  Map<int, int> sweepAnim = {};
  int sweepId = 0;

  // Sawdust particle burst on clear: cells + style per cell.
  Map<int, int> burstCells = {};
  int burstId = 0;

  // Combo celebration overlay.
  int celebrateCombo = 0;
  int celebrateId = 0;

  // Floating score popup.
  String? popupText;
  int popupId = 0;

  bool paused = false;
  bool gameOver = false;
  bool gameOverByTimeout = false;
  bool newBest = false;
  bool resolving = false;
  DateTime? _resolveStart;

  String hintMsg = 'Pick up a block, set it on the bench';
  Hint? hint;
  bool levelUpFlash = false;

  Timer? _popupTimer;
  Timer? _watchdog;
  int _lastTickSecond = -1;
  bool _disposed = false;

  GameController({
    required this.mode,
    required this.audio,
    required this.settings,
    this.dailyDate,
  }) {
    engine = BlockFillEngine(
      seed: mode == GameMode.daily && dailyDate != null
          ? BlockFillEngine.dailySeed(_parseDate(dailyDate!))
          : null,
      mode: mode,
      stainCount: BlockStyles.all.length,
    );
    newGame();
    // Watchdog: blitz countdown, invariant validation, stuck-op recovery.
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _watch());
  }

  static DateTime _parseDate(String d) {
    final p = d.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  int get score => engine.score;
  int get best {
    switch (mode) {
      case GameMode.blitz:
        return settings.bestBlitz;
      case GameMode.daily:
        return settings.dailyBestFor(dailyDate ?? '');
      case GameMode.classic:
        return settings.bestClassic;
    }
  }

  String get modeLabel {
    switch (mode) {
      case GameMode.blitz:
        return 'BLITZ';
      case GameMode.daily:
        return 'DAILY';
      case GameMode.classic:
        return 'CLASSIC';
    }
  }

  void newGame() {
    engine.reset();
    selected = -1;
    dragging = false;
    ghostCells = {};
    aboutToClear = {};
    sweepAnim = {};
    burstCells = {};
    celebrateCombo = 0;
    popupText = null;
    paused = false;
    gameOver = false;
    gameOverByTimeout = false;
    newBest = false;
    resolving = false;
    _resolveStart = null;
    hint = null;
    _lastTickSecond = -1;
    hintMsg = mode == GameMode.blitz
        ? '120 seconds on the clock — fill fast!'
        : 'Pick up a block, set it on the bench';
    notifyListeners();
    audio.gameStart();
  }

  /// 1-second watchdog: engine-owned blitz countdown, invariant validation,
  /// stuck-placement recovery, and low-time tick sounds.
  void _watch() {
    if (_disposed || gameOver || paused) return;
    var changed = false;

    // Blitz countdown lives in the engine.
    if (mode == GameMode.blitz) {
      final before = engine.timeLeftMs;
      engine.tick(1000);
      if (engine.timeLeftMs != before) changed = true;
      final secs = (engine.timeLeftMs / 1000).ceil();
      if (secs != _lastTickSecond) {
        _lastTickSecond = secs;
        if (secs <= 10 && secs > 0) audio.tick();
        changed = true;
      }
      if (engine.timedOut && !gameOver) {
        gameOverByTimeout = true;
        _finishGame();
        return;
      }
    }

    // Invariant validation: heal by ending cleanly if the engine ever
    // reports a broken state (should never happen; belt and suspenders).
    final problem = engine.validate();
    if (problem != null) {
      debugPrint('BlockFill watchdog: engine invariant broken: $problem');
      if (!gameOver) {
        _finishGame();
        return;
      }
    }

    // Stuck-placement recovery: a placement op must settle in seconds.
    if (resolving && _resolveStart != null) {
      if (DateTime.now().difference(_resolveStart!).inSeconds > 8) {
        debugPrint('BlockFill watchdog: recovering stuck placement op');
        resolving = false;
        _resolveStart = null;
        cancelDrag();
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  void setHint(String m) {
    hintMsg = m;
    notifyListeners();
  }

  void _bump() {
    if (settings.hapticsOn) {
      HapticFeedback.lightImpact();
    }
  }

  // --- selection ----------------------------------------------------------

  void selectPiece(int i) {
    if (gameOver || paused || resolving) return;
    if (engine.tray[i] == null) return;
    _bump();
    audio.click();
    selected = (selected == i) ? -1 : i;
    hint = null;
    notifyListeners();
  }

  void rotateSelected() {
    if (gameOver || paused || resolving) return;
    final t = selected >= 0 ? engine.tray[selected] : null;
    if (t == null) return;
    _bump();
    audio.rotate();
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
      audio.invalid();
      _bump();
      hintMsg = 'It won\'t fit there — try another spot';
      notifyListeners();
      return;
    }
    resolving = true;
    _resolveStart = DateTime.now();
    final placedIndex = selected;
    selected = -1;
    dragging = false;
    ghostCells = {};
    aboutToClear = {};
    hint = null;
    final prevLevel = engine.level; // read BEFORE place (level-up detection)

    try {
      final res = engine.place(placedIndex, r, c);
      notifyListeners();

      _bump();
      await audio.place();

      if (res.lines > 0) {
        // Sweep animation + sawdust particle burst + sounds.
        sweepAnim = Map<int, int>.from(res.clearedStains);
        sweepId++;
        burstCells = Map<int, int>.from(res.clearedStains);
        burstId++;
        notifyListeners();
        await audio.clear();
        if (res.combo >= 2) {
          await audio.combo();
          celebrateCombo = res.combo;
          celebrateId++;
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
        await Future<void>.delayed(const Duration(milliseconds: 500));
        burstCells = {};
        celebrateCombo = 0;
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
    } finally {
      // Always settle: the watchdog also enforces this, but try/finally
      // guarantees no stuck state even if audio or timers throw.
      resolving = false;
      _resolveStart = null;
    }

    if (engine.isGameOver) {
      await _finishGame();
    } else {
      notifyListeners();
    }
  }

  Future<void> _finishGame() async {
    if (gameOver) return;
    gameOver = true;
    switch (mode) {
      case GameMode.blitz:
        newBest = await settings.recordBlitz(engine.score);
        break;
      case GameMode.daily:
        newBest = await settings.recordDaily(dailyDate ?? '', engine.score);
        break;
      case GameMode.classic:
        newBest = await settings.recordClassic(engine.score);
        break;
    }
    notifyListeners();
    if (newBest) {
      await audio.newBest();
    } else {
      await audio.gameOver();
    }
  }

  void _popup(String text) {
    popupText = text;
    popupId++;
    notifyListeners();
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(milliseconds: 1100), () {
      if (_disposed) return;
      popupText = null;
      notifyListeners();
    });
  }

  // --- hint ----------------------------------------------------------------

  void showHint() {
    if (gameOver || paused || resolving) return;
    final h = engine.findHint();
    if (h == null) return;
    audio.hint();
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
    _disposed = true;
    _watchdog?.cancel();
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
