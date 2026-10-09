// Generates synthesized workshop WAV files for Block Fill.
// Run: dart tool/gen_sounds.dart  (writes into assets/sounds/)
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sr = 22050;
final _r = Random(20261009);

Float64List _buf(double seconds) => Float64List((seconds * sr).ceil());

void _addKnock(Float64List b, double t, double freq,
    {double dur = 0.16, double amp = 0.9, double noise = 0.5}) {
  final start = (t * sr).round();
  final n = (dur * sr).round();
  for (var i = 0; i < n && start + i < b.length; i++) {
    final x = i / sr;
    final env = exp(-x * 34);
    final tone = sin(2 * pi * freq * x) * 0.7 +
        sin(2 * pi * freq * 2.76 * x) * 0.22 * exp(-x * 60) +
        sin(2 * pi * freq * 5.4 * x) * 0.08 * exp(-x * 90);
    // woody click transient: short noise burst
    final nz = (_r.nextDouble() * 2 - 1) * exp(-x * 420) * noise;
    b[start + i] += (tone * env + nz) * amp;
  }
}

void _addMarimba(Float64List b, double t, double freq,
    {double dur = 1.1, double amp = 0.55}) {
  final start = (t * sr).round();
  final n = (dur * sr).round();
  for (var i = 0; i < n && start + i < b.length; i++) {
    final x = i / sr;
    final atk = (1 - exp(-x * 260));
    final env = atk * exp(-x * 4.2);
    final tone = sin(2 * pi * freq * x) +
        sin(2 * pi * freq * 4.0 * x) * 0.25 * exp(-x * 9) +
        sin(2 * pi * freq * 9.8 * x) * 0.06 * exp(-x * 14);
    b[start + i] += tone * env * amp;
  }
}

void _addSwish(Float64List b, double t,
    {double dur = 0.5, double amp = 0.5, double f0 = 900, double f1 = 2600}) {
  final start = (t * sr).round();
  final n = (dur * sr).round();
  var lp = 0.0;
  for (var i = 0; i < n && start + i < b.length; i++) {
    final x = i / sr;
    final frac = x / dur;
    final cutoff = f0 + (f1 - f0) * frac; // rising sawing swish
    final a = 1 - exp(-2 * pi * cutoff / sr);
    final nz = _r.nextDouble() * 2 - 1;
    lp += a * (nz - lp);
    final env = sin(pi * frac); // swell up and down
    b[start + i] += lp * env * amp * 1.6;
  }
}

void _addThud(Float64List b, double t, double freq,
    {double dur = 0.3, double amp = 0.85}) {
  final start = (t * sr).round();
  final n = (dur * sr).round();
  for (var i = 0; i < n && start + i < b.length; i++) {
    final x = i / sr;
    final env = exp(-x * 22);
    final tone = sin(2 * pi * freq * x) * 0.9 +
        sin(2 * pi * freq * 1.5 * x) * 0.3 * exp(-x * 40);
    final nz = (_r.nextDouble() * 2 - 1) * exp(-x * 300) * 0.35;
    b[start + i] += (tone * env + nz) * amp;
  }
}

void _writeWav(String path, Float64List b) {
  // soft limiter + fade out last 20ms to avoid clicks on loop
  var peak = 0.0;
  for (final v in b) {
    peak = max(peak, v.abs());
  }
  final g = peak > 0.98 ? 0.98 / peak : 1.0;
  final fade = (0.02 * sr).round();
  final data = Int16List(b.length);
  for (var i = 0; i < b.length; i++) {
    var v = b[i] * g;
    if (i > b.length - fade) v *= (b.length - i) / fade;
    data[i] = (v.clamp(-1.0, 1.0) * 32767).round();
  }
  final out = ByteData(44 + data.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      out.setUint8(o + i, s.codeUnitAt(i));
    }
  }
  str(0, 'RIFF');
  out.setUint32(4, 36 + data.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  out.setUint32(16, 16, Endian.little);
  out.setUint16(20, 1, Endian.little);
  out.setUint16(22, 1, Endian.little);
  out.setUint32(24, sr, Endian.little);
  out.setUint32(28, sr * 2, Endian.little);
  out.setUint16(32, 2, Endian.little);
  out.setUint16(34, 16, Endian.little);
  str(36, 'data');
  out.setUint32(40, data.length * 2, Endian.little);
  for (var i = 0; i < data.length; i++) {
    out.setInt16(44 + i * 2, data[i], Endian.little);
  }
  File(path).writeAsBytesSync(out.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path (${(File(path).lengthSync() / 1024).toStringAsFixed(0)} KB)');
}

// A-minor pentatonic across two octaves
const _penta = <double>[
  110.0, 130.81, 146.83, 164.81, 196.0, // A2 C3 D3 E3 G3
  220.0, 261.63, 293.66, 329.63, 392.0, // A3 C4 D4 E4 G4
  440.0, 523.25, // A4 C5
];

void main() {
  const dir = 'assets/sounds';

  // click — crisp wooden button knock
  var b = _buf(0.25);
  _addKnock(b, 0.0, 320, amp: 0.75);
  _writeWav('$dir/click.wav', b);

  // place — block set down: knock + soft follow-up knock
  b = _buf(0.4);
  _addKnock(b, 0.0, 210, amp: 0.95);
  _addKnock(b, 0.07, 168, amp: 0.5, dur: 0.12);
  _writeWav('$dir/place.wav', b);

  // rotate — small tap
  b = _buf(0.2);
  _addKnock(b, 0.0, 420, amp: 0.55, dur: 0.1);
  _writeWav('$dir/rotate.wav', b);

  // invalid — dull low thunk
  b = _buf(0.35);
  _addThud(b, 0.0, 105, amp: 0.9);
  _addThud(b, 0.09, 92, amp: 0.55, dur: 0.22);
  _writeWav('$dir/invalid.wav', b);

  // clear — sawing swish + sweep of blocks
  b = _buf(0.9);
  _addSwish(b, 0.0, dur: 0.55, amp: 0.5, f0: 700, f1: 2800);
  _addKnock(b, 0.28, 240, amp: 0.5);
  _addKnock(b, 0.36, 300, amp: 0.55);
  _addKnock(b, 0.44, 380, amp: 0.6);
  _writeWav('$dir/clear.wav', b);

  // combo — three rising mallet knocks
  b = _buf(0.7);
  _addKnock(b, 0.0, 262, amp: 0.8);
  _addKnock(b, 0.14, 330, amp: 0.85);
  _addKnock(b, 0.28, 392, amp: 0.9);
  _writeWav('$dir/combo.wav', b);

  // hint — soft brass-pin tack
  b = _buf(0.25);
  _addKnock(b, 0.0, 620, amp: 0.5, dur: 0.1, noise: 0.7);
  _writeWav('$dir/hint.wav', b);

  // game_start — little mallet warm-up run
  b = _buf(1.4);
  _addMarimba(b, 0.0, 220.0);
  _addMarimba(b, 0.22, 261.63);
  _addMarimba(b, 0.44, 293.66);
  _addMarimba(b, 0.66, 329.63, dur: 0.9);
  _addKnock(b, 0.9, 196, amp: 0.4);
  _writeWav('$dir/game_start.wav', b);

  // win / new best — warm wooden fanfare arpeggio
  b = _buf(2.2);
  final seq = [220.0, 261.63, 293.66, 329.63, 392.0, 440.0, 523.25];
  for (var i = 0; i < seq.length; i++) {
    _addMarimba(b, i * 0.22, seq[i], dur: i == seq.length - 1 ? 1.2 : 0.8);
  }
  _writeWav('$dir/newbest.wav', b);

  // gameover — descending soft thuds
  b = _buf(1.8);
  _addThud(b, 0.0, 196, amp: 0.8);
  _addThud(b, 0.4, 164.81, amp: 0.8);
  _addThud(b, 0.8, 130.81, amp: 0.85, dur: 0.6);
  _writeWav('$dir/gameover.wav', b);

  // menu_music — 16 s gentle workshop ambience loop (A-minor pentatonic)
  b = _buf(16.0);
  final menu = <List<double>>[
    [0.0, 5], [1.0, 3], [2.0, 1], [4.0, 4], [5.0, 6], [6.0, 4],
    [8.0, 3], [9.0, 5], [10.0, 7], [12.0, 8], [13.0, 7], [14.0, 5],
  ];
  for (final e in menu) {
    _addMarimba(b, e[0], _penta[e[1].toInt()], dur: 1.6, amp: 0.42);
  }
  _addKnock(b, 0.0, 110, amp: 0.28, dur: 0.5);
  _addKnock(b, 8.0, 98, amp: 0.28, dur: 0.5);
  _writeWav('$dir/menu_music.wav', b);

  // game_music — 24 s steady workshop rhythm loop
  b = _buf(24.0);
  const beat = 0.6; // 100 bpm
  final pattern = [5, -1, 3, 4, 6, -1, 4, 3, 5, 7, 6, -1, 4, 3, 1, 3];
  for (var bar = 0; bar < 2; bar++) {
    for (var i = 0; i < 40; i++) {
      final t = bar * 40 * beat + i * beat;
      final deg = pattern[i % 16];
      if (deg >= 0) _addMarimba(b, t, _penta[deg], dur: 0.7, amp: 0.34);
      if (i % 8 == 0) _addKnock(b, t, 110, amp: 0.3, dur: 0.4);
      if (i % 8 == 4) _addKnock(b, t, 130.81, amp: 0.2, dur: 0.3);
    }
  }
  _writeWav('$dir/game_music.wav', b);
}
