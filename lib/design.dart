import 'package:flutter/material.dart';

/// Carpenter's Workshop design tokens — Block Fill.
/// Stitch is the visual source of truth (stitch-batch5/blockfill/DESIGN.md).
/// Pseudo-3D skeuomorphic realism: oak blocks, dovetail joints, walnut tray,
/// kraft paper, brass hardware. Warm lamp from top-left. No neon, no glow.
abstract final class Workshop {
  // Palette
  static const oakLight = Color(0xFFC89B62);
  static const oakMid = Color(0xFFA9763F);
  static const oakDark = Color(0xFF7A5227);
  static const walnut = Color(0xFF4A2E15);
  static const workbench = Color(0xFF8A5E33);
  static const sawdust = Color(0xFFE3C99B);
  static const kraft = Color(0xFFD9BE8C);
  static const kraftDark = Color(0xFFC4A468);
  static const burntUmber = Color(0xFF2E1D0E);
  static const brickRed = Color(0xFFA63A22);
  static const sage = Color(0xFF7C8A4F);
  static const lampAmber = Color(0xFFF2B950);
  static const brass = Color(0xFFB08A3E);

  // Wood stains (pieces). Standard palette:
  static const stainOak = Color(0xFFA9763F);
  static const stainWalnut = Color(0xFF6B4423);
  static const stainCherry = Color(0xFF9C4A2F);
  static const stainAsh = Color(0xFFC8A96A);
  static const stainPine = Color(0xFF8A7A3A);

  /// Color-blind-safe stains: oak, walnut, cherry, ash, pine — distinguishable
  /// by hue AND lightness, never color-only information.
  static const stainBlind = [
    Color(0xFFD9A441), // golden oak (light)
    Color(0xFF4A2E15), // dark walnut (dark)
    Color(0xFFA63A22), // cherry brick (red)
    Color(0xFF7C8A4F), // sage ash (green)
    Color(0xFF3E6B8A), // blue pine (cool)
  ];

  static const stains = [stainOak, stainWalnut, stainCherry, stainAsh, stainPine];

  // Typography
  static const display = 'Fraunces';
  static const ui = 'Karla';
  static const numerals = 'ZillaSlab';

  /// Wood-burned heading: Fraunces, burnt umber, with a deboss shadow.
  static TextStyle burned(double size, {Color color = burntUmber}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
        shadows: const [
          Shadow(color: Color(0x40F2B950), offset: Offset(0, 1), blurRadius: 0),
          Shadow(color: Color(0x80000000), offset: Offset(0, -0.5), blurRadius: 1),
        ],
      );

  static TextStyle label(double size, {Color color = burntUmber}) => TextStyle(
        fontFamily: ui,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.4,
      );

  static TextStyle body(double size, {Color color = burntUmber}) => TextStyle(
        fontFamily: ui,
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle digits(double size, {Color color = burntUmber}) => TextStyle(
        fontFamily: numerals,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Tactile shadows (lamp from top-left)
  static List<BoxShadow> get restingShadow => const [
        BoxShadow(color: Color(0x59000000), blurRadius: 6, offset: Offset(2, 4)),
        BoxShadow(color: Color(0x26F2B950), blurRadius: 2, offset: Offset(-1, -1)),
      ];

  static List<BoxShadow> get liftedShadow => const [
        BoxShadow(color: Color(0x73000000), blurRadius: 18, offset: Offset(7, 12)),
      ];

  static List<BoxShadow> get insetShadow => const [
        BoxShadow(
            color: Color(0xA62E1D0E),
            blurRadius: 6,
            offset: Offset(2, 3),
            spreadRadius: -2),
      ];

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: workbench,
      colorScheme: const ColorScheme.light(
        primary: oakMid,
        onPrimary: burntUmber,
        surface: kraft,
        onSurface: burntUmber,
      ),
      textTheme: TextTheme(
        displayLarge: burned(34),
        titleLarge: burned(24),
        bodyLarge: body(16),
        labelLarge: label(13),
      ),
    );
  }
}
