import 'package:flutter/material.dart';
import '../audio.dart';
import '../design.dart';
import '../engine.dart';
import '../widgets/wood.dart';
import 'game_screen.dart';

/// "BENCH FULL!" workshop certificate: kraft certificate with brass pins,
/// NEW BEST ribbon, craftsman nameplate, stat rows, PLAY AGAIN + MENU.
class GameOverScreen extends StatelessWidget {
  final int score;
  final bool isBest;
  final int piecesPlaced;
  final int linesCleared;
  final int bestCombo;
  final int level;
  final bool daily;
  final String? dailyDate;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.isBest,
    required this.piecesPlaced,
    required this.linesCleared,
    required this.bestCombo,
    required this.level,
    this.daily = false,
    this.dailyDate,
  });

  @override
  Widget build(BuildContext context) {
    final title = BlockFillEngine.titleFor(score);
    return Scaffold(
      body: WorkbenchBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Workshop certificate.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      KraftPlaque(
                        tilt: -0.015,
                        padding:
                            const EdgeInsets.fromLTRB(26, 34, 26, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('BENCH FULL!',
                                style: Workshop.burned(34),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text(
                                daily
                                    ? 'daily challenge complete'
                                    : 'no more joints will fit',
                                style: Workshop.body(14,
                                    color: Workshop.burntUmber
                                        .withValues(alpha: 0.75))),
                            const SizedBox(height: 14),
                            // Craftsman nameplate.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Workshop.oakDark,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Workshop.walnut, width: 2),
                              ),
                              child: Text(title.toUpperCase(),
                                  style: Workshop.burned(16,
                                      color: Workshop.sawdust)),
                            ),
                            const SizedBox(height: 16),
                            _statRow('FINAL SCORE', '$score', big: true),
                            _statRow('PIECES PLACED', '$piecesPlaced'),
                            _statRow('LINES CLEARED', '$linesCleared'),
                            _statRow('BEST COMBO',
                                bestCombo >= 2 ? '×$bestCombo' : '—'),
                            _statRow('CRAFTSMAN LEVEL', '$level'),
                          ],
                        ),
                      ),
                      if (isBest)
                        Positioned(
                          top: -12,
                          right: 6,
                          child: Transform.rotate(
                            angle: 0.12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Workshop.brickRed,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Workshop.walnut, width: 1.5),
                                boxShadow: Workshop.restingShadow,
                              ),
                              child: Text('NEW BEST!',
                                  style: Workshop.label(14,
                                      color: Workshop.sawdust)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  OakButton(
                    label: daily ? 'BACK TO BENCH' : 'PLAY AGAIN',
                    fontSize: 24,
                    onTap: () {
                      Sound.I.click();
                      if (daily) {
                        Navigator.of(context).pop();
                        return;
                      }
                      Sound.I.gameMusic();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const GameScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Sound.I.click();
                      Navigator.of(context).pop();
                    },
                    child: Text('MENU',
                        style: Workshop.label(15,
                            color: Workshop.sawdust)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Workshop.label(big ? 13 : 11,
                  color:
                      Workshop.burntUmber.withValues(alpha: 0.7))),
          Text(value, style: Workshop.digits(big ? 30 : 20)),
        ],
      ),
    );
  }
}
