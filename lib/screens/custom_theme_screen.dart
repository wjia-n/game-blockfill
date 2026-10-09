import 'package:flutter/material.dart';
import '../design.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/workshop_themes.dart';
import '../widgets/wood.dart';

/// Custom workshop creator (PRO): pick block, board, bench and accent
/// colors from preset swatches. Saved automatically; becomes the 'custom'
/// theme.
class CustomThemeScreen extends StatefulWidget {
  final WorkshopAudio audio;
  final BlockFillSettings settings;
  const CustomThemeScreen({
    super.key,
    required this.audio,
    required this.settings,
  });

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  static const _keys = ['block', 'board', 'bench', 'accent'];
  static const _labels = {
    'block': 'Block material',
    'board': 'Board tray',
    'bench': 'Workbench',
    'accent': 'Brass accent',
  };

  static const _swatches = [
    0xFFA9763F, 0xFF6B4423, 0xFF9C4A2F, 0xFFC8A96A, 0xFFD9A441, 0xFF8A5A30,
    0xFF4A2E15, 0xFF7C8A4F, 0xFF3E6B8A, 0xFF6E9A8A, 0xFFB08A3E, 0xFFD4AF37,
    0xFF8A5232, 0xFF5F3A2A, 0xFF2E3238, 0xFF6E747C, 0xFFE8DCC0, 0xFFA63A22,
  ];

  WorkshopThemeDef get _t => widget.settings.theme;

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    // Live preview of the custom theme being built.
    final preview = WorkshopThemes.customFrom(s.customColors);
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) => Scaffold(
        body: WorkbenchBackground(
          theme: t,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: Row(
                    children: [
                      WoodKnob(
                        theme: t,
                        size: 44,
                        icon: Icons.arrow_back,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('MY WORKSHOP',
                            style: Workshop.burned(22, color: t.text),
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 56),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Live preview plank.
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: preview.bench,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: preview.trayFrame, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: preview.blockMid,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border(
                                    top: BorderSide(
                                        color: preview.blockLight, width: 2),
                                    left: BorderSide(
                                        color: preview.blockLight, width: 2),
                                    bottom: BorderSide(
                                        color: preview.blockDark, width: 3),
                                    right: BorderSide(
                                        color: preview.blockDark, width: 3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: preview.trayInset,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: preview.accent, width: 2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('Preview',
                                  style: Workshop.burned(20,
                                      color: preview.text)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final k in _keys) ...[
                          Text(_labels[k]!,
                              style: Workshop.label(12, color: t.text)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final argb in _swatches)
                                GestureDetector(
                                  onTap: () {
                                    widget.audio.click();
                                    s.setCustomColor(k, argb);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(argb),
                                      border: Border.all(
                                        color: s.customColors[k] == argb
                                            ? t.lampAmber
                                            : t.trayFrame,
                                        width: s.customColors[k] == argb
                                            ? 3
                                            : 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        OakButton(
                          theme: t,
                          label: 'USE THIS WORKSHOP',
                          fontSize: 18,
                          width: double.infinity,
                          onTap: () {
                            widget.audio.click();
                            s.setTheme('custom');
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              widget.audio.click();
                              s.resetCustomColors();
                            },
                            child: Text('Reset colors',
                                style: Workshop.label(13,
                                    color: t.comboRed)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
