import 'package:shared_preferences/shared_preferences.dart';

/// Persistent workshop records: best scores per mode, daily-challenge
/// leaderboard (one entry per date), settings, and progress reset.
/// RULES.md §8: high score persisted locally per mode (Classic / Daily).
class ScoreStore {
  ScoreStore._();
  static final ScoreStore I = ScoreStore._();

  int bestClassic = 0;
  final Map<String, int> dailyBest = {}; // 'yyyy-MM-dd' -> best score
  String? dailyPlayedDate; // date string of today's completed attempt

  bool hapticsOn = true;
  bool colorBlind = false;
  int stainChoice = 0; // preferred wood-stain swatch 0..4

  static const _p = 'bf_';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    bestClassic = p.getInt('${_p}best_classic') ?? 0;
    dailyPlayedDate = p.getString('${_p}daily_played');
    hapticsOn = p.getBool('${_p}haptics') ?? true;
    colorBlind = p.getBool('${_p}colorblind') ?? false;
    stainChoice = p.getInt('${_p}stain') ?? 0;
    for (final k in p.getKeys()) {
      if (k.startsWith('${_p}daily_')) {
        final v = p.getInt(k);
        if (v != null) dailyBest[k.substring('${_p}daily_'.length)] = v;
      }
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('${_p}best_classic', bestClassic);
    if (dailyPlayedDate != null) {
      await p.setString('${_p}daily_played', dailyPlayedDate!);
    }
    await p.setBool('${_p}haptics', hapticsOn);
    await p.setBool('${_p}colorblind', colorBlind);
    await p.setInt('${_p}stain', stainChoice);
    for (final e in dailyBest.entries) {
      await p.setInt('${_p}daily_${e.key}', e.value);
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

  Future<void> setHaptics(bool v) async {
    hapticsOn = v;
    await _save();
  }

  Future<void> setColorBlind(bool v) async {
    colorBlind = v;
    await _save();
  }

  Future<void> setStain(int i) async {
    stainChoice = i;
    await _save();
  }

  /// Brick-red RESET PROGRESS plank: wipes all scores and daily records.
  Future<void> resetProgress() async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getKeys().where((k) => k.startsWith(_p)).toList();
    for (final k in keys) {
      await p.remove(k);
    }
    bestClassic = 0;
    dailyBest.clear();
    dailyPlayedDate = null;
  }
}
