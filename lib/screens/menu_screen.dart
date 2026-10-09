import 'package:flutter/material.dart';
import '../design.dart';
import '../engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/workshop_themes.dart';
import '../widgets/wood.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu: game logo, wood-burned title, profile chip, CLASSIC / BLITZ /
/// DAILY planks, BEST plaques, PRO plank, settings knob.
class MenuScreen extends StatefulWidget {
  final WorkshopAudio audio;
  final BlockFillSettings settings;
  final StoreService store;
  const MenuScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  WorkshopThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  void _play(GameMode mode) {
    final s = widget.settings;
    if (mode == GameMode.daily && s.dailyPlayedToday()) {
      final best =
          s.dailyBestFor(BlockFillSettings.dateKey(DateTime.now()));
      showDialog<void>(
        context: context,
        builder: (ctx) => WorkshopDialog(
          theme: _t,
          title: 'Already planed today',
          body:
              'Today\'s daily board is done — you scored $best.\nCome back tomorrow for fresh timber!',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Back to bench',
                  style: Workshop.label(14, color: _t.text)),
            ),
          ],
        ),
      );
      return;
    }
    widget.audio.click();
    widget.audio.startGameMusic();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          dailyDate: mode == GameMode.daily
              ? BlockFillSettings.dateKey(DateTime.now())
              : null,
          audio: widget.audio,
          settings: s,
        ),
      ),
    )
        .then((_) {
      widget.audio.startMenuMusic();
      setState(() {});
    });
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    )
        .then((_) => setState(() {}));
  }

  void _openSettings() {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => SettingsScreen(
                  audio: widget.audio,
                  settings: widget.settings,
                  store: widget.store,
                )))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return Scaffold(
      body: WorkbenchBackground(
        theme: t,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 44),
                      // Game logo.
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: t.accent, width: 3),
                          boxShadow: Workshop.restingShadow,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/blockfill_logo.png',
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 14),
                      Text('BLOCK FILL',
                          style: Workshop.burned(44, color: t.text)),
                      Text('THE CARPENTER\'S WORKSHOP',
                          style: Workshop.label(12, color: t.textSoft)),
                      const SizedBox(height: 14),
                      // Profile chip.
                      GestureDetector(
                        onTap: _openSettings,
                        child: KraftPlaque(
                          theme: t,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person,
                                  size: 16, color: t.textSoft),
                              const SizedBox(width: 6),
                              Text(s.playerName,
                                  style: Workshop.label(13, color: t.text)),
                              const SizedBox(width: 4),
                              Icon(Icons.edit,
                                  size: 13,
                                  color: t.textSoft
                                      .withValues(alpha: 0.7)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OakButton(
                        theme: t,
                        label: 'PLAY',
                        fontSize: 26,
                        onTap: () => _play(GameMode.classic),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PlankButton(
                            theme: t,
                            label: 'BLITZ',
                            sub: '2-minute rush',
                            onTap: () => _play(GameMode.blitz),
                          ),
                          const SizedBox(width: 12),
                          PlankButton(
                            theme: t,
                            label: 'DAILY',
                            sub: 'challenge',
                            onTap: () => _play(GameMode.daily),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      PlankButton(
                        theme: t,
                        label: s.isPro ? 'PRO WORKSHOP ✓' : 'GO PRO',
                        sub: s.isPro ? 'all unlocked' : 'free vs pro',
                        wide: true,
                        onTap: _openPro,
                      ),
                      const SizedBox(height: 20),
                      // BEST score plaques.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          KraftPlaque(
                            theme: t,
                            tilt: -0.02,
                            child: Column(
                              children: [
                                Text('BEST',
                                    style: Workshop.label(10,
                                        color: t.textSoft)),
                                Text('${s.bestClassic}',
                                    style: Workshop.digits(22,
                                        color: t.text)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          KraftPlaque(
                            theme: t,
                            tilt: 0.02,
                            child: Column(
                              children: [
                                Text('BLITZ BEST',
                                    style: Workshop.label(10,
                                        color: t.textSoft)),
                                Text('${s.bestBlitz}',
                                    style: Workshop.digits(22,
                                        color: t.text)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: WoodKnob(
                  theme: t,
                  icon: Icons.settings,
                  onTap: _openSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlankButton extends StatelessWidget {
  final WorkshopThemeDef theme;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final bool wide;
  const PlankButton({
    super.key,
    required this.theme,
    required this.label,
    required this.sub,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? 232 : 110,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: theme.blockMid,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            top: BorderSide(color: theme.blockLight, width: 2),
            left: BorderSide(color: theme.blockLight, width: 2),
            bottom: BorderSide(color: theme.blockDark, width: 4),
            right: BorderSide(color: theme.blockDark, width: 4),
          ),
          boxShadow: Workshop.restingShadow,
        ),
        child: Column(
          children: [
            Text(label,
                style: Workshop.burned(17, color: theme.text),
                textAlign: TextAlign.center),
            Text(sub,
                style: Workshop.label(9, color: theme.textSoft),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class WorkshopDialog extends StatelessWidget {
  final WorkshopThemeDef theme;
  final String title;
  final String body;
  final List<Widget> actions;
  const WorkshopDialog({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: KraftPlaque(
        theme: theme,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: Workshop.burned(20, color: theme.text),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: Workshop.body(14, color: theme.textSoft),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
