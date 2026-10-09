import 'package:flutter/material.dart';
import '../design.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/workshop_themes.dart';
import '../widgets/wood.dart';
import 'custom_theme_screen.dart';
import 'menu_screen.dart';
import 'pro_screen.dart';

/// Workshop settings: profile name, theme picker (14), block styles (12),
/// board accents (6), custom creator, sound/music/haptics/color-blind,
/// volumes, reset progress.
class SettingsScreen extends StatefulWidget {
  final WorkshopAudio audio;
  final BlockFillSettings settings;
  final StoreService? store;
  const SettingsScreen({
    super.key,
    required this.audio,
    required this.settings,
    this.store,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final FocusNode _nameFocus;

  WorkshopThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.settings.playerName);
    _nameFocus = FocusNode();
    _nameFocus.addListener(_commitNameOnFocusLoss);
  }

  /// Commits the rename when the field loses focus — not just on
  /// keyboard-done or the check button. Without this, a tap-elsewhere or
  /// back-navigation silently drops the typed name and renames appear
  /// "not saved".
  void _commitNameOnFocusLoss() {
    if (_nameFocus.hasFocus) return;
    _commitName();
  }

  /// Canonicalises the field through setPlayerName and echoes the stored
  /// value back so the field never shows an unsaved/uncleaned variant.
  void _commitName() {
    final s = widget.settings;
    if (_name.text == s.playerName) return;
    s.setPlayerName(_name.text);
    _name.text = s.playerName;
  }

  @override
  void dispose() {
    // Belt and braces: commit any uncommitted rename on screen teardown.
    _commitName();
    _nameFocus.removeListener(_commitNameOnFocusLoss);
    _nameFocus.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) => Scaffold(
        body: WorkbenchBackground(
          theme: t,
          child: SafeArea(
            child: Column(
              children: [
                _header(t),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(t, 'CARPENTER PROFILE', [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: t.trayInset,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: t.trayFrame, width: 1.5),
                                  ),
                                  child: TextField(
                                    controller: _name,
                                    focusNode: _nameFocus,
                                    style: Workshop.body(16, color: t.kraft),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Your name',
                                      hintStyle: Workshop.body(16,
                                          color: t.kraft.withValues(
                                              alpha: 0.5)),
                                    ),
                                    onSubmitted: (v) {
                                      _commitName();
                                      widget.audio.click();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              WoodKnob(
                                theme: t,
                                size: 44,
                                icon: Icons.check,
                                onTap: () {
                                  _commitName();
                                  widget.audio.click();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ]),
                        _section(t, 'WORKSHOP THEME', [
                          _SwatchGrid(
                            theme: t,
                            count: WorkshopThemes.all.length + 1,
                            selected: s.themeId == 'custom'
                                ? WorkshopThemes.all.length
                                : WorkshopThemes.all
                                    .indexWhere((e) => e.id == s.themeId),
                            locked: (i) {
                              if (i >= WorkshopThemes.all.length) {
                                return !s.isPro; // custom
                              }
                              return !s.isPro &&
                                  WorkshopThemes.all[i].proOnly;
                            },
                            color: (i) => i >= WorkshopThemes.all.length
                                ? null
                                : WorkshopThemes.all[i].blockMid,
                            label: (i) => i >= WorkshopThemes.all.length
                                ? 'Custom'
                                : WorkshopThemes.all[i].name,
                            onTap: (i) {
                              widget.audio.click();
                              if (i >= WorkshopThemes.all.length) {
                                if (!s.isPro) {
                                  _proNudge();
                                  return;
                                }
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (_) =>
                                            CustomThemeScreen(
                                              audio: widget.audio,
                                              settings: s,
                                            )))
                                    .then((_) => setState(() {}));
                                return;
                              }
                              s.setTheme(WorkshopThemes.all[i].id);
                            },
                          ),
                        ]),
                        _section(t, 'BLOCK MATERIAL', [
                          _SwatchGrid(
                            theme: t,
                            count: BlockStyles.all.length,
                            selected: s.blockStyleId,
                            locked: (i) =>
                                !s.isPro && BlockStyles.isPro(i),
                            color: (i) => BlockStyles.all[i].mid,
                            label: (i) => BlockStyles.all[i].name,
                            onTap: (i) {
                              widget.audio.click();
                              if (!s.isPro && BlockStyles.isPro(i)) {
                                _proNudge();
                                return;
                              }
                              s.setBlockStyle(i);
                            },
                          ),
                        ]),
                        _section(t, 'BOARD ACCENT', [
                          _SwatchGrid(
                            theme: t,
                            count: BoardAccents.all.length,
                            selected: s.boardAccentId,
                            locked: (i) =>
                                !s.isPro && BoardAccents.isPro(i),
                            color: (i) => BoardAccents.all[i].frame,
                            label: (i) => BoardAccents.all[i].name,
                            onTap: (i) {
                              widget.audio.click();
                              if (!s.isPro && BoardAccents.isPro(i)) {
                                _proNudge();
                                return;
                              }
                              s.setBoardAccent(i);
                            },
                          ),
                        ]),
                        _section(t, 'SOUND', [
                          _row(t, 'Music', BoltLatch(
                            theme: t,
                            value: s.musicOn,
                            onChanged: (v) {
                              s.setMusic(v);
                              widget.audio.click();
                              if (v) widget.audio.startMenuMusic();
                            },
                          )),
                          _row(t, 'Music volume', WoodSlider(
                            theme: t,
                            value: s.musicVolume,
                            onChanged: s.setMusicVolume,
                          )),
                          _row(t, 'Sound effects', BoltLatch(
                            theme: t,
                            value: s.sfxOn,
                            onChanged: (v) {
                              s.setSfx(v);
                              widget.audio.click();
                            },
                          )),
                          _row(t, 'Effects volume', WoodSlider(
                            theme: t,
                            value: s.sfxVolume,
                            onChanged: s.setSfxVolume,
                          )),
                        ]),
                        _section(t, 'WORKSHOP', [
                          _row(t, 'Haptics', BoltLatch(
                            theme: t,
                            value: s.hapticsOn,
                            onChanged: (v) {
                              s.setHaptics(v);
                              widget.audio.click();
                            },
                          )),
                          _row(t, 'Color-blind safe stains', BoltLatch(
                            theme: t,
                            value: s.colorBlind,
                            onChanged: (v) {
                              s.setColorBlind(v);
                              widget.audio.click();
                            },
                          )),
                        ]),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: () => _confirmReset(t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: t.comboRed,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                top: BorderSide(
                                    color: t.kraft.withValues(alpha: 0.5),
                                    width: 2),
                                left: BorderSide(
                                    color: t.kraft.withValues(alpha: 0.5),
                                    width: 2),
                                bottom: BorderSide(
                                    color: t.trayFrame, width: 4),
                                right: BorderSide(
                                    color: t.trayFrame, width: 4),
                              ),
                              boxShadow: Workshop.restingShadow,
                            ),
                            alignment: Alignment.center,
                            child: Text('RESET PROGRESS',
                                style: Workshop.burned(18, color: t.kraft)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Scores and appearance reset.\nName and PRO unlock are kept.',
                            style: Workshop.body(12, color: t.textSoft),
                            textAlign: TextAlign.center,
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

  Widget _header(WorkshopThemeDef t) {
    return Padding(
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
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: t.blockMid,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: t.trayFrame, width: 2),
                boxShadow: Workshop.restingShadow,
              ),
              child: Text('WORKSHOP SETTINGS',
                  style: Workshop.burned(20, color: t.text),
                  textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _section(
      WorkshopThemeDef t, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: KraftPlaque(
        theme: t,
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: Workshop.label(13, color: t.text),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(WorkshopThemeDef t, String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Workshop.body(15, color: t.text))),
          control,
        ],
      ),
    );
  }

  void _proNudge() {
    final store = widget.store;
    if (store == null) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProScreen(
              audio: widget.audio,
              settings: widget.settings,
              store: store,
            )));
  }

  void _confirmReset(WorkshopThemeDef t) {
    widget.audio.click();
    showDialog<void>(
      context: context,
      builder: (ctx) => WorkshopDialog(
        theme: t,
        title: 'Reset the workbench?',
        body:
            'All scores, daily records and appearance choices will be wiped. Your name and PRO unlock stay.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep', style: Workshop.label(14, color: t.text)),
          ),
          TextButton(
            onPressed: () {
              widget.settings.resetProgress();
              Navigator.pop(ctx);
              setState(() {});
            },
            child:
                Text('Reset', style: Workshop.label(14, color: t.comboRed)),
          ),
        ],
      ),
    );
  }
}

/// Grid of selectable swatches with PRO locks.
class _SwatchGrid extends StatelessWidget {
  final WorkshopThemeDef theme;
  final int count;
  final int selected;
  final bool Function(int) locked;
  final Color? Function(int) color;
  final String Function(int) label;
  final void Function(int) onTap;
  const _SwatchGrid({
    required this.theme,
    required this.count,
    required this.selected,
    required this.locked,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: count,
      itemBuilder: (_, i) {
        final isSel = i == selected;
        final isLocked = locked(i);
        final c = color(i);
        return GestureDetector(
          onTap: () => onTap(i),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c ?? theme.accentLight,
                  border: Border.all(
                    color: isSel ? theme.lampAmber : theme.trayFrame,
                    width: isSel ? 3 : 2,
                  ),
                  boxShadow:
                      isSel ? Workshop.liftedShadow : Workshop.restingShadow,
                ),
                child: c == null
                    ? Icon(Icons.palette,
                        color: theme.textSoft, size: 24)
                    : isLocked
                        ? const Icon(Icons.lock,
                            color: Color(0xAA000000), size: 20)
                        : null,
              ),
              const SizedBox(height: 4),
              Text(
                label(i),
                style: Workshop.label(8, color: theme.textSoft),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
