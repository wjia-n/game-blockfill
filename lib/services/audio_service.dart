import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Procedural workshop audio for Block Fill — all sounds synthesized in code
/// as WAV bytes and cached. Wood knocks, mallet thuds, sawing swishes.
///
/// Reliability design (every call is safe to repeat and safe to overlap):
/// - Clips are synthesized ONCE and cached; starting music never blocks the
///   UI thread after the first build.
/// - A [_musicGen] generation counter serializes track changes: every
///   start/stop bumps the generation, in-flight work from an older request
///   aborts, and the LATEST request always wins. Music is app-scoped and
///   never silently dies.
/// - Lifecycle uses pause()/resume() so an interruption (call, backgrounding)
///   resumes exactly where it left off instead of restarting or dying.
/// - Every public method catches player errors; audio can never crash the app.
class WorkshopAudio {

  static const int _rate = 22050;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final _rand = Random(20261009);

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.8;
  double sfxVolume = 0.8;

  final Map<String, Uint8List> _cache = {};

  int _musicGen = 0;
  bool _musicBusy = false;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  WorkshopAudio() {
    _music.setReleaseMode(ReleaseMode.loop);
  }

  void configure({
    required bool musicOn,
    required bool sfxOn,
    required double musicVolume,
    required double sfxVolume,
  }) {
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    this.musicVolume = musicVolume.clamp(0.0, 1.0);
    this.sfxVolume = sfxVolume.clamp(0.0, 1.0);
    _music.setVolume(musicOn ? this.musicVolume * 0.55 : 0.0);
    _sfx.setVolume(sfxOn ? this.sfxVolume : 0.0);
    if (!musicOn) stopMusic();
  }

  /// Pre-build clips off the critical path. Safe to call any time.
  Future<void> prewarm() async {
    if (_disposed) return;
    await Future(() {});
    _menuBytes();
    _gameBytes();
  }

  // ---------------------------------------------------------- WAV synthesis
  Uint8List _wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void writeStr(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      final v = samples[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _env(int i, int n, {double attack = 0.02, double decay = 2.2}) {
    final t = i / n;
    final a = (t / attack).clamp(0.0, 1.0);
    final d = pow(1 - t, decay).toDouble();
    return a * d;
  }

  /// Wooden knock: low thump + woody click transient.
  List<double> _knock(double freq, double secs,
      {double amp = 0.9, double noise = 0.5}) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final tone = sin(2 * pi * freq * t) * 0.7 * exp(-t * 34) +
          sin(2 * pi * freq * 2.76 * t) * 0.22 * exp(-t * 60) +
          sin(2 * pi * freq * 5.4 * t) * 0.08 * exp(-t * 90);
      final nz = (_rand.nextDouble() * 2 - 1) * exp(-t * 420) * noise;
      out[i] = _env(i, n, attack: 0.004) * (tone + nz) * amp;
    }
    return out;
  }

  /// Marimba-like pluck: warm wooden baritone for music and melodies.
  List<double> _marimba(double freq, double secs, {double amp = 0.55}) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final atk = 1 - exp(-t * 260);
      final env = atk * exp(-t * 4.2);
      out[i] = (sin(2 * pi * freq * t) +
              sin(2 * pi * freq * 4.0 * t) * 0.25 * exp(-t * 9) +
              sin(2 * pi * freq * 9.8 * t) * 0.06 * exp(-t * 14)) *
          env *
          amp;
    }
    return out;
  }

  /// Sawing swish: filtered noise sweeping up — the clear sound.
  List<double> _swish(double secs,
      {double amp = 0.5, double f0 = 900, double f1 = 2600}) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    var lp = 0.0;
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final frac = t / secs;
      final cutoff = f0 + (f1 - f0) * frac;
      final a = 1 - exp(-2 * pi * cutoff / _rate);
      final nz = _rand.nextDouble() * 2 - 1;
      lp += a * (nz - lp);
      out[i] = lp * sin(pi * frac) * amp * 1.6;
    }
    return out;
  }

  List<double> _arp(List<double> freqs, double noteSecs, double gapSecs,
      {double amp = 0.5}) {
    final out = <double>[];
    for (final f in freqs) {
      final tone = _marimba(f, noteSecs, amp: amp);
      out.addAll(tone);
      out.addAll(List<double>.filled((_rate * gapSecs).round(), 0));
    }
    return out;
  }

  List<double> _padChord(List<double> freqs, double secs) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      double v = 0;
      for (final f in freqs) {
        final t = i / _rate;
        v += sin(2 * pi * f * t) + 0.3 * sin(2 * pi * f * 2 * t);
      }
      v /= freqs.length * 1.3;
      final t = i / n;
      out[i] = v * (0.35 + 0.65 * sin(pi * t.clamp(0.0, 1.0)));
    }
    return out;
  }

  void _mixInto(List<double> base, List<double> add, int start, double gain) {
    for (int i = 0; i < add.length && start + i < base.length; i++) {
      base[start + i] += add[i] * gain;
    }
  }

  Uint8List _clip(String key, List<double> Function() build) =>
      _cache.putIfAbsent(key, () => _wav(build()));

  Uint8List _menuBytes() => _clip('music_menu', () {
        // F# arpeggiated 0 – 3 – 5 – 4, 16s loop. Unique to blockfill.
        final notes = [185.00, 233.08, 277.18, 233.08, 246.94, 311.12, 369.99, 311.12, 311.12, 369.99, 466.16, 369.99, 277.18, 349.22, 415.30, 349.22];
        final out = <double>[];
        final noteLen = 16.0 / notes.length;
        for (final n in notes) {
          out.addAll(_marimba(n, noteLen * 0.9));
          final gap = List<double>.filled((_rate * noteLen * 0.1).round(), 0);
          out.addAll(gap);
        }
        // Soft pad underneath
        final pad = _padChord([185.00, 233.08, 277.18], 16.0);
        for (int i = 0; i < out.length && i < pad.length; i++) {
          out[i] += pad[i] * 0.3;
        }
        return out;
      });


  Uint8List _gameBytes() => _clip('music_game', () {
        // F# bass + melody 0 – 3 – 5 – 4, 16s loop. Unique to blockfill.
        final bassNotes = [92.50, 123.47, 155.56, 138.59];
        final melNotes = [554.36, 739.98, 932.32, 830.60];
        final out = List<double>.filled((_rate * 16).round(), 0);
        final segLen = (_rate * 4).round();
        for (int s = 0; s < 4; s++) {
          final bass = _knock(bassNotes[s], 3.5);
          final mel = _marimba(melNotes[s], 1.2);
          for (int i = 0; i < bass.length && s * segLen + i < out.length; i++) {
            out[s * segLen + i] += bass[i] * 0.5;
          }
          final melStart = s * segLen + segLen ~/ 4;
          for (int i = 0; i < mel.length && melStart + i < out.length; i++) {
            out[melStart + i] += mel[i] * 0.35;
          }
        }
        return out;
      });


  // ------------------------------------------------------------------ SFX
  Future<void> _play(Uint8List bytes) async {
    if (!sfxOn || _disposed) return;
    try {
      await _sfx.play(BytesSource(bytes)).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> click() => _play(_clip('click', () => _knock(2200, 0.05, amp: 0.5, noise: 0.7)));
  Future<void> place() => _play(_clip('place', () => _knock(170, 0.14)));
  Future<void> rotate() => _play(_clip('rotate', () => _swish(0.09, amp: 0.35, f0: 1400, f1: 2400)));
  Future<void> invalid() => _play(_clip('invalid', () => _knock(120, 0.18, amp: 0.8)));
  Future<void> clear() => _play(_clip('clear', () {
        final s = _swish(0.4);
        _mixInto(s, _knock(330, 0.2), (_rate * 0.18).round(), 0.8);
        return s;
      }));
  Future<void> combo() => _play(_clip(
      'combo', () => _arp([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.14, 0.02)));
  Future<void> hint() => _play(_clip('hint', () => _knock(880, 0.08, amp: 0.5)));
  Future<void> tick() => _play(_clip('tick', () => _knock(1500, 0.04, amp: 0.45, noise: 0.6)));
  Future<void> gameStart() => _play(_clip('start', () {
        final out = List<double>.filled((_rate * 0.5).round(), 0);
        _mixInto(out, _knock(220, 0.16), 0, 1.0);
        _mixInto(out, _knock(330, 0.16), (_rate * 0.12).round(), 1.0);
        _mixInto(out, _knock(440, 0.2), (_rate * 0.24).round(), 1.0);
        return out;
      }));
  Future<void> newBest() => _play(_clip('newbest',
      () => _arp([523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0], 0.16, 0.03)));
  Future<void> gameOver() => _play(_clip(
      'gameover', () => _arp([392.0, 329.63, 261.63, 196.0], 0.24, 0.05, amp: 0.55)));

  // ----------------------------------------------------------------- music
  Future<void> _startTrack(String track, Uint8List Function() bytes) async {
    if (_disposed) return;
    final gen = ++_musicGen;
    if (_currentTrack == track && !_pausedByLifecycle) {
      try {
        await _music.resume();
      } catch (_) {}
      return;
    }
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (gen != _musicGen || _disposed || !musicOn) return;
    _musicBusy = true;
    try {
      await _music.stop().timeout(const Duration(seconds: 2));
      if (gen != _musicGen || _disposed || !musicOn) return;
      _currentTrack = track;
      _pausedByLifecycle = false;
      await _music.play(BytesSource(bytes())).timeout(const Duration(seconds: 3));
    } catch (_) {
      if (gen == _musicGen) _currentTrack = null;
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> startMenuMusic() => _startTrack('menu', _menuBytes);
  Future<void> startGameMusic() => _startTrack('game', _gameBytes);

  /// App-scoped stop: cancels any pending start, then stops. Used only when
  /// the user turns music OFF — never on screen navigation.
  Future<void> stopMusic() async {
    ++_musicGen;
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (_disposed) return;
    try {
      await _music.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}
    _currentTrack = null;
    _pausedByLifecycle = false;
  }

  /// App went to background / interruption: pause (not stop) so we resume
  /// exactly where we left off.
  Future<void> onAppPaused() async {
    if (_disposed || _currentTrack == null) return;
    try {
      await _music.pause();
      _pausedByLifecycle = true;
    } catch (_) {}
  }

  /// App came back: resume only if we paused it and music is still wanted.
  Future<void> onAppResumed() async {
    if (_disposed || !musicOn || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    try {
      await _music.resume();
    } catch (_) {
      final track = _currentTrack;
      _currentTrack = null;
      if (track == 'menu') {
        await startMenuMusic();
      } else if (track == 'game') {
        await startGameMusic();
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _sfx.dispose();
      await _music.dispose();
    } catch (_) {}
  }
}
