import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/workshop_themes.dart';

/// Persisted workshop state for Block Fill: audio, profile, appearance
/// (theme / block style / board accent / custom theme), Pro unlock, and
/// best scores per mode (Classic / Blitz / Daily). Survives app restarts.
/// RULES.md §8: high score persisted locally per mode.
class BlockFillSettings extends ChangeNotifier {
  static const _p = 'bf_';
  static const _kMusic = 'bf_music_on';
  static const _kSfx = 'bf_sfx_on';
  static const _kMusicVol = 'bf_music_vol';
  static const _kSfxVol = 'bf_sfx_vol';
  static const _kHaptics = 'bf_haptics';
  static const _kColorBlind = 'bf_colorblind';
  static const _kName = 'bf_player_name';
  static const _kTheme = 'bf_theme_id';
  static const _kBlockStyle = 'bf_block_style';
  static const _kAccent = 'bf_board_accent';
  static const _kIsPro = 'bf_is_pro';
  static const _kBestClassic = 'bf_best_classic';
  static const _kBestBlitz = 'bf_best_blitz';
  static const _kDailyPlayed = 'bf_daily_played';
  static const _kCustomPrefix = 'bf_custom_';

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.8;
  double sfxVolume = 0.8;
  bool hapticsOn = true;
  bool colorBlind = false;
  String playerName = 'Carpenter';
  String themeId = 'classic';
  int blockStyleId = 0;
  int boardAccentId = 0;
  bool isPro = false;

  int bestClassic = 0;
  int bestBlitz = 0;
  final Map<String, int> dailyBest = {}; // 'yyyy-MM-dd' -> best score
  String? dailyPlayedDate;

  /// Custom theme colors (ARGB ints).
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'block': 0xFFA9763F,
    'board': 0xFF4A2E15,
    'bench': 0xFF8A5E33,
    'accent': 0xFFB08A3E,
  };

  WorkshopThemeDef get customTheme =>
      WorkshopThemes.customFrom(customColors);

  WorkshopThemeDef get theme =>
      WorkshopThemes.byId(themeId, custom: customTheme);

  SharedPreferences? _prefs;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    musicVolume = p.getDouble(_kMusicVol) ?? 0.8;
    sfxVolume = p.getDouble(_kSfxVol) ?? 0.8;
    hapticsOn = p.getBool(_kHaptics) ?? true;
    colorBlind = p.getBool(_kColorBlind) ?? false;
    final nm = (p.getString(_kName) ?? '').trim();
    playerName = nm.isEmpty ? 'Carpenter' : nm;
    themeId = p.getString(_kTheme) ?? 'classic';
    blockStyleId =
        (p.getInt(_kBlockStyle) ?? 0).clamp(0, BlockStyles.all.length - 1);
    boardAccentId =
        (p.getInt(_kAccent) ?? 0).clamp(0, BoardAccents.all.length - 1);
    isPro = p.getBool(_kIsPro) ?? false;
    bestClassic = p.getInt(_kBestClassic) ?? 0;
    bestBlitz = p.getInt(_kBestBlitz) ?? 0;
    dailyPlayedDate = p.getString(_kDailyPlayed);
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    for (final k in p.getKeys()) {
      if (k.startsWith('${_p}daily_')) {
        final v = p.getInt(k);
        if (v != null) dailyBest[k.substring('${_p}daily_'.length)] = v;
      }
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kMusicVol, musicVolume);
    await p.setDouble(_kSfxVol, sfxVolume);
    await p.setBool(_kHaptics, hapticsOn);
    await p.setBool(_kColorBlind, colorBlind);
    await p.setString(_kName, playerName);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kBlockStyle, blockStyleId);
    await p.setInt(_kAccent, boardAccentId);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kBestClassic, bestClassic);
    await p.setInt(_kBestBlitz, bestBlitz);
    if (dailyPlayedDate != null) {
      await p.setString(_kDailyPlayed, dailyPlayedDate!);
    }
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
    for (final e in dailyBest.entries) {
      await p.setInt('${_p}daily_${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (WorkshopThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (BlockStyles.isPro(blockStyleId)) {
      blockStyleId = 0;
      changed = true;
    }
    if (BoardAccents.isPro(boardAccentId)) {
      boardAccentId = 0;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setSfxVolume(double v) async {
    sfxVolume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setHaptics(bool v) async {
    hapticsOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setColorBlind(bool v) async {
    colorBlind = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? 'Carpenter' : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes require Pro; silently ignore otherwise (UI shows lock).
    if (!isPro && WorkshopThemes.isProTheme(id)) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBlockStyle(int v) async {
    v = v.clamp(0, BlockStyles.all.length - 1);
    if (!isPro && BlockStyles.isPro(v)) return;
    blockStyleId = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBoardAccent(int v) async {
    v = v.clamp(0, BoardAccents.all.length - 1);
    if (!isPro && BoardAccents.isPro(v)) return;
    boardAccentId = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  int bestFor(String mode) {
    switch (mode) {
      case 'blitz':
        return bestBlitz;
      case 'daily':
        return 0; // daily bests are per-date; see dailyBestFor
      default:
        return bestClassic;
    }
  }

  /// Returns true when this score is a new best for the mode.
  Future<bool> recordClassic(int score) async {
    var isBest = false;
    if (score > bestClassic) {
      bestClassic = score;
      isBest = true;
    }
    await _save();
    return isBest;
  }

  Future<bool> recordBlitz(int score) async {
    var isBest = false;
    if (score > bestBlitz) {
      bestBlitz = score;
      isBest = true;
    }
    await _save();
    return isBest;
  }

  /// Records a daily-challenge attempt. One attempt per day (RULES.md §7).
  Future<bool> recordDaily(String date, int score) async {
    dailyPlayedDate = date;
    var isBest = false;
    if (score > (dailyBest[date] ?? 0)) {
      dailyBest[date] = score;
      isBest = true;
    }
    await _save();
    return isBest;
  }

  bool dailyPlayedToday() => dailyPlayedDate == dateKey(DateTime.now());

  int dailyBestFor(String date) => dailyBest[date] ?? 0;

  /// Brick-red RESET PROGRESS plank: wipes scores, daily records, and
  /// appearance choices — but keeps the player name and Pro unlock.
  Future<void> resetProgress() async {
    final p = _prefs;
    if (p == null) return;
    final keepName = playerName;
    final keepPro = isPro;
    final keys = p.getKeys().where((k) => k.startsWith(_p)).toList();
    for (final k in keys) {
      if (k == _kName || k == _kIsPro) continue;
      await p.remove(k);
    }
    bestClassic = 0;
    bestBlitz = 0;
    dailyBest.clear();
    dailyPlayedDate = null;
    themeId = 'classic';
    blockStyleId = 0;
    boardAccentId = 0;
    customColors = Map.of(_defaultCustomColors);
    playerName = keepName;
    isPro = keepPro;
    notifyListeners();
    await _save();
  }
}
