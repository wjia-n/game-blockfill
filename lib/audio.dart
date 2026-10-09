import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central workshop sound manager. All audio flows through here.
/// Workshop identity: wood knocks, sawing swishes, mallet thuds.
/// Music + SFX toggles and volumes persist via SharedPreferences.
class Sound {
  Sound._();
  static final Sound I = Sound._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.8;
  double sfxVolume = 0.8;
  bool _loaded = false;

  static const _kMusic = 'bf_music_on';
  static const _kSfx = 'bf_sfx_on';
  static const _kMusicVol = 'bf_music_vol';
  static const _kSfxVol = 'bf_sfx_vol';

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    musicVolume = p.getDouble(_kMusicVol) ?? 0.8;
    sfxVolume = p.getDouble(_kSfxVol) ?? 0.8;
    await _music.setReleaseMode(ReleaseMode.loop);
    await _applyVolumes();
  }

  Future<void> _applyVolumes() async {
    await _sfx.setVolume(sfxOn ? sfxVolume : 0.0);
    await _music.setVolume(musicOn ? musicVolume * 0.6 : 0.0);
  }

  Future<void> setMusic(bool on) async {
    musicOn = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMusic, on);
    await _applyVolumes();
    if (!on) await _music.stop();
  }

  Future<void> setSfx(bool on) async {
    sfxOn = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSfx, on);
    await _applyVolumes();
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0.0, 1.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kMusicVol, musicVolume);
    await _applyVolumes();
  }

  Future<void> setSfxVolume(double v) async {
    sfxVolume = v.clamp(0.0, 1.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kSfxVol, sfxVolume);
    await _applyVolumes();
  }

  // --- one-shot SFX -------------------------------------------------------
  Future<void> _play(String file) async {
    if (!sfxOn) return;
    try {
      await _sfx.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }

  Future<void> click() => _play('click.wav');
  Future<void> place() => _play('place.wav');
  Future<void> rotate() => _play('rotate.wav');
  Future<void> invalid() => _play('invalid.wav');
  Future<void> clear() => _play('clear.wav');
  Future<void> combo() => _play('combo.wav');
  Future<void> hint() => _play('hint.wav');
  Future<void> gameStart() => _play('game_start.wav');
  Future<void> newBest() => _play('newbest.wav');
  Future<void> gameOver() => _play('gameover.wav');

  // --- music --------------------------------------------------------------
  Future<void> menuMusic() async {
    if (!musicOn) return;
    try {
      await _music.stop();
      await _music.play(AssetSource('sounds/menu_music.wav'));
    } catch (_) {}
  }

  Future<void> gameMusic() async {
    if (!musicOn) return;
    try {
      await _music.stop();
      await _music.play(AssetSource('sounds/game_music.wav'));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
  }

  void dispose() {
    _sfx.dispose();
    _music.dispose();
  }
}
