import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const BlockFillApp());

class BlockFillApp extends StatelessWidget {
  const BlockFillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.elegantSerif,
      title: 'Block Fill',
      tagline: 'Cozy block-fitting zen. Fill rows, clear lines, feel like a genius!',
      emoji: '🧱',
      slug: 'blockfill',
      howToPlay:
          '• You get 3 random block pieces at a time.\n• Tap a piece, then tap the board to drop it in.\n• Fill a whole row or column to blast it away for bonus points.\n• Game over when none of your pieces fit anywhere.\n• Plan ahead — the board fills up faster than you think! 😅',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => BlockFillScreen(players: players, callbacks: cb),
    );
  }
}
