import 'package:flutter/material.dart';
import 'dart:math';
import '../audio.dart';
import '../design.dart';
import '../engine.dart';
import '../scores.dart';
import '../widgets/wood.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Main menu: wood-burned title plank, oak polyomino dressing,
/// PLAY block, CLASSIC / DAILY CHALLENGE planks, BEST plaque, settings knob.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    Sound.I.menuMusic();
  }

  void _play({required bool daily}) {
    if (daily && ScoreStore.I.dailyPlayedToday()) {
      final best = ScoreStore.I.dailyBestFor(
          ScoreStore.dateKey(DateTime.now()));
      showDialog<void>(
        context: context,
        builder: (ctx) => _WorkshopDialog(
          title: 'Already planed today',
          body:
              'Today\'s daily board is done — you scored $best.\nCome back tomorrow for fresh timber!',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Back to bench',
                  style: Workshop.label(14, color: Workshop.burntUmber)),
            ),
          ],
        ),
      );
      return;
    }
    Sound.I.click();
    Sound.I.gameMusic();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          daily: daily,
          dailyDate: daily ? ScoreStore.dateKey(DateTime.now()) : null,
        ),
      ),
    ).then((_) => Sound.I.menuMusic());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WorkbenchBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 56),
                      // Wood-burned title plank.
                      _TitlePlank(),
                      const SizedBox(height: 18),
                      // Decorative oak polyomino arrangement.
                      const _MenuDressing(),
                      const SizedBox(height: 26),
                      OakButton(
                        label: 'PLAY',
                        fontSize: 26,
                        onTap: () => _play(daily: false),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PlankButton(
                            label: 'CLASSIC',
                            onTap: () => _play(daily: false),
                          ),
                          const SizedBox(width: 12),
                          _PlankButton(
                            label: 'DAILY',
                            sub: 'challenge',
                            onTap: () => _play(daily: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      // BEST score plaque with brass pin.
                      KraftPlaque(
                        tilt: 0.02,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('BEST  ',
                                style: Workshop.label(13,
                                    color: Workshop.burntUmber
                                        .withValues(alpha: 0.75))),
                            Text('${ScoreStore.I.bestClassic}',
                                style: Workshop.digits(26)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              // Round wooden settings knob, top-right.
              Positioned(
                top: 8,
                right: 16,
                child: WoodKnob(
                  icon: Icons.settings,
                  onTap: () {
                    Sound.I.click();
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => const SettingsScreen()))
                        .then((_) => setState(() {}));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitlePlank extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
      decoration: BoxDecoration(
        color: Workshop.oakMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Workshop.walnut, width: 4),
        boxShadow: Workshop.restingShadow,
      ),
      child: Column(
        children: [
          Text('BLOCK FILL',
              style: Workshop.burned(40), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('a carpenter\'s puzzle',
              style: Workshop.body(15,
                  color: Workshop.burntUmber.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

/// Static oak polyomino arrangement (L-tetromino, 2x2 square, bar).
class _MenuDressing extends StatelessWidget {
  const _MenuDressing();

  @override
  Widget build(BuildContext context) {
    const cell = 26.0;
    TrayPiece piece(String art, int stain) =>
        TrayPiece(_shapeFor(art), stain);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.rotate(
          angle: -0.08,
          child: _dressedPiece(piece('#..\n###', 0), cell),
        ),
        const SizedBox(width: 14),
        Transform.rotate(
          angle: 0.05,
          child: _dressedPiece(piece('##\n##', 2), cell),
        ),
        const SizedBox(width: 14),
        Transform.rotate(
          angle: 0.1,
          child: _dressedPiece(piece('####', 1), cell),
        ),
      ],
    );
  }

  Widget _dressedPiece(TrayPiece p, double cell) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 8, offset: Offset(3, 6)),
        ],
      ),
      child: PieceView(piece: p, cellSize: cell),
    );
  }
}

PieceShape _shapeFor(String art) {
  final rows = art.split('\n');
  final cells = <Point<int>>[];
  var maxC = 0;
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      if (rows[r][c] == '#') {
        cells.add(Point(c, r));
        if (c > maxC) maxC = c;
      }
    }
  }
  return PieceShape(cells, maxC + 1, rows.length);
}

class _PlankButton extends StatefulWidget {
  final String label;
  final String? sub;
  final VoidCallback onTap;
  const _PlankButton({required this.label, this.sub, required this.onTap});

  @override
  State<_PlankButton> createState() => _PlankButtonState();
}

class _PlankButtonState extends State<_PlankButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: Workshop.oakDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Workshop.walnut, width: 2.5),
          boxShadow: _down
              ? const [
                  BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 2,
                      offset: Offset(1, 1)),
                ]
              : Workshop.restingShadow,
        ),
        child: Column(
          children: [
            Text(widget.label,
                style: Workshop.burned(17, color: Workshop.sawdust)),
            if (widget.sub != null)
              Text(widget.sub!,
                  style: Workshop.body(11,
                      color: Workshop.sawdust.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _WorkshopDialog extends StatelessWidget {
  final String title;
  final String body;
  final List<Widget> actions;
  const _WorkshopDialog({
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: KraftPlaque(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Workshop.burned(22), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(body,
                style: Workshop.body(15), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions),
          ],
        ),
      ),
    );
  }
}
