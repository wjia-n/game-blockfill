import 'package:flutter/material.dart';
import '../audio.dart';
import '../design.dart';
import '../scores.dart';
import '../widgets/wood.dart';

/// Workshop settings: bolt-latch toggles (sound, music, haptics,
/// color-blind safe stains + wood-stain swatches), planed-wood rail sliders
/// (music/SFX volume), brick-red RESET PROGRESS plank.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = ScoreStore.I;
    final sound = Sound.I;
    return Scaffold(
      body: WorkbenchBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header plank with round wooden back button.
                Row(
                  children: [
                    WoodKnob(
                      icon: Icons.arrow_back,
                      size: 48,
                      onTap: () {
                        sound.click();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Workshop.oakMid,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Workshop.walnut, width: 3),
                          boxShadow: Workshop.restingShadow,
                        ),
                        child: Text('WORKSHOP SETTINGS',
                            style: Workshop.burned(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Kraft panel.
                KraftPlaque(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 22),
                  child: Column(
                    children: [
                      _toggleRow(
                        'Sound effects',
                        'wood knocks & sawing',
                        sound.sfxOn,
                        (v) async {
                          await sound.setSfx(v);
                          setState(() {});
                          if (v) sound.click();
                        },
                      ),
                      _toggleRow(
                        'Music',
                        'workshop ambience',
                        sound.musicOn,
                        (v) async {
                          await sound.setMusic(v);
                          setState(() {});
                        },
                      ),
                      _toggleRow(
                        'Haptics',
                        'feel every joint',
                        store.hapticsOn,
                        (v) async {
                          await store.setHaptics(v);
                          setState(() {});
                        },
                      ),
                      _toggleRow(
                        'Color-blind safe stains',
                        'high-contrast wood tones',
                        store.colorBlind,
                        (v) async {
                          await store.setColorBlind(v);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('WOOD STAIN',
                            style: Workshop.label(12)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var i = 0; i < 5; i++)
                            _stainSwatch(i, store),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('MUSIC VOLUME',
                            style: Workshop.label(12)),
                      ),
                      WoodSlider(
                        value: sound.musicVolume,
                        onChanged: (v) async {
                          await sound.setMusicVolume(v);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('SOUND VOLUME',
                            style: Workshop.label(12)),
                      ),
                      WoodSlider(
                        value: sound.sfxVolume,
                        onChanged: (v) async {
                          await sound.setSfxVolume(v);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Brick-red RESET PROGRESS plank.
                _ResetPlank(onDone: () => setState(() {})),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Workshop.burned(17)),
                Text(sub,
                    style: Workshop.body(12,
                        color: Workshop.burntUmber
                            .withValues(alpha: 0.7))),
              ],
            ),
          ),
          BoltLatch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _stainSwatch(int i, ScoreStore store) {
    final selected = store.stainChoice == i;
    final colors =
        store.colorBlind ? Workshop.stainBlind : Workshop.stains;
    return GestureDetector(
      onTap: () async {
        await store.setStain(i);
        Sound.I.click();
        setState(() {});
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[i],
          border: Border.all(
            color: selected ? Workshop.lampAmber : Workshop.walnut,
            width: selected ? 3.5 : 2,
          ),
          boxShadow: Workshop.restingShadow,
        ),
        child: selected
            ? const Icon(Icons.check,
                color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

class _ResetPlank extends StatefulWidget {
  final VoidCallback onDone;
  const _ResetPlank({required this.onDone});

  @override
  State<_ResetPlank> createState() => _ResetPlankState();
}

class _ResetPlankState extends State<_ResetPlank> {
  bool _down = false;

  void _confirm() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: KraftPlaque(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saw it all off?',
                  style: Workshop.burned(22),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                  'This clears every best score and daily record. The bench forgets everything.',
                  style: Workshop.body(14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('KEEP IT',
                        style: Workshop.label(14)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ScoreStore.I.resetProgress();
                      if (ctx.mounted) Navigator.pop(ctx);
                      widget.onDone();
                    },
                    child: Text('SAW IT OFF',
                        style: Workshop.label(14,
                            color: Workshop.brickRed)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        Sound.I.click();
        _confirm();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(vertical: 14),
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: Workshop.brickRed,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Workshop.walnut, width: 3),
          boxShadow: _down
              ? const [
                  BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 2,
                      offset: Offset(1, 1)),
                ]
              : Workshop.restingShadow,
        ),
        alignment: Alignment.center,
        child: Text('RESET PROGRESS',
            style: Workshop.burned(18, color: Workshop.sawdust)),
      ),
    );
  }
}
