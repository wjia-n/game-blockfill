import 'package:flutter/material.dart';
import '../design.dart';
import '../engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/workshop_themes.dart';
import '../widgets/wood.dart';
import 'game_screen.dart';
import 'menu_screen.dart';

/// Workshop certificate: kraft certificate with brass pins, NEW BEST ribbon,
/// craftsman nameplate, stat rows, PLAY AGAIN + MENU.
class GameOverScreen extends StatelessWidget {
  final int score;
  final bool isBest;
  final bool timedOut;
  final int piecesPlaced;
  final int linesCleared;
  final int bestCombo;
  final int level;
  final GameMode mode;
  final String? dailyDate;
  final WorkshopAudio audio;
  final BlockFillSettings settings;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.isBest,
    required this.piecesPlaced,
    required this.linesCleared,
    required this.bestCombo,
    required this.level,
    required this.mode,
    required this.audio,
    required this.settings,
    this.timedOut = false,
    this.dailyDate,
  });

  @override
  Widget build(BuildContext context) {
    final t = settings.theme;
    final title = BlockFillEngine.titleFor(score);
    final headline = timedOut ? 'TIME\'S UP!' : 'BENCH FULL!';
    final sub = timedOut
        ? 'the clock ran out on ${settings.playerName}'
        : (mode == GameMode.daily
            ? 'daily challenge complete'
            : 'no more joints will fit');
    return Scaffold(
      body: WorkbenchBackground(
        theme: t,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      KraftPlaque(
                        theme: t,
                        tilt: -0.015,
                        padding:
                            const EdgeInsets.fromLTRB(26, 34, 26, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(headline,
                                style: Workshop.burned(34, color: t.text),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text(sub,
                                style: Workshop.body(14, color: t.textSoft)),
                            const SizedBox(height: 6),
                            Text(settings.playerName,
                                style: Workshop.label(13, color: t.textSoft)),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: t.blockDark,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: t.trayFrame, width: 2),
                              ),
                              child: Text(title.toUpperCase(),
                                  style: Workshop.burned(16,
                                      color: t.kraft)),
                            ),
                            const SizedBox(height: 16),
                            _stat(t, 'Final score', '$score'),
                            _stat(t, 'Pieces placed', '$piecesPlaced'),
                            _stat(t, 'Lines cleared', '$linesCleared'),
                            _stat(t, 'Best combo',
                                bestCombo >= 2 ? '×$bestCombo' : '—'),
                            _stat(t, 'Craftsman level', '$level'),
                          ],
                        ),
                      ),
                      if (isBest)
                        Positioned(
                          top: -14,
                          right: -10,
                          child: Transform.rotate(
                            angle: 0.08,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: t.comboRed,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: t.trayFrame, width: 1.5),
                                boxShadow: Workshop.restingShadow,
                              ),
                              child: Text('NEW BEST',
                                  style: Workshop.label(12,
                                      color: t.kraft)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  OakButton(
                    theme: t,
                    label: 'PLAY AGAIN',
                    onTap: () {
                      audio.click();
                      audio.startGameMusic();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            mode: mode,
                            dailyDate: dailyDate,
                            audio: audio,
                            settings: settings,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  PlankButton(
                    theme: t,
                    label: 'MENU',
                    sub: 'back to workshop',
                    wide: true,
                    onTap: () {
                      audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(WorkshopThemeDef t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Workshop.body(14, color: t.textSoft))),
          Text(value, style: Workshop.digits(18, color: t.text)),
        ],
      ),
    );
  }
}
