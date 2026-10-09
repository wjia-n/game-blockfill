import 'package:flutter/material.dart';

/// Carpenter's Workshop theme catalog for Block Fill.
///
/// Every theme stays inside the physical-material world (real woods, stone,
/// sea glass, iron, brass) — the variety comes from different materials and
/// hardware, never neon/glow/cyberpunk. Themes drive ALL visible colors:
/// pieces, tray, bench, kraft plaques, accents.
class WorkshopThemeDef {
  final String id;
  final String name;
  final bool proOnly;
  // Piece material.
  final Color blockLight;
  final Color blockMid;
  final Color blockDark;
  // Board tray.
  final Color trayFrame;
  final Color trayInset;
  final Color trayGroove;
  // Background bench.
  final Color bench;
  final Color benchDeep;
  // Kraft paper UI.
  final Color kraft;
  final Color kraftDark;
  final Color text;
  final Color textSoft;
  // Hardware accents.
  final Color accent;
  final Color accentLight;
  final Color comboRed;
  final Color sage;
  final Color lampAmber;

  const WorkshopThemeDef({
    required this.id,
    required this.name,
    this.proOnly = false,
    required this.blockLight,
    required this.blockMid,
    required this.blockDark,
    required this.trayFrame,
    required this.trayInset,
    required this.trayGroove,
    required this.bench,
    required this.benchDeep,
    required this.kraft,
    required this.kraftDark,
    required this.text,
    required this.textSoft,
    required this.accent,
    required this.accentLight,
    required this.comboRed,
    required this.sage,
    required this.lampAmber,
  });
}

/// Block piece styles: physical materials for the polyominoes.
class BlockStyleDef {
  final String name;
  final bool proOnly;
  final Color light;
  final Color mid;
  final Color dark;
  const BlockStyleDef({
    required this.name,
    required this.light,
    required this.mid,
    required this.dark,
    this.proOnly = false,
  });
}

/// Board accent: trim treatment for the 8x8 tray frame.
class BoardAccentDef {
  final String name;
  final bool proOnly;
  final Color frame;
  final Color groove;
  const BoardAccentDef({
    required this.name,
    required this.frame,
    required this.groove,
    this.proOnly = false,
  });
}

class WorkshopThemes {
  /// First 4 themes are FREE; the rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'walnut',
    'cherry',
    'pine',
  ];

  static const List<WorkshopThemeDef> all = [
    WorkshopThemeDef(
      id: 'classic',
      name: 'Classic Oak',
      blockLight: Color(0xFFC89B62),
      blockMid: Color(0xFFA9763F),
      blockDark: Color(0xFF7A5227),
      trayFrame: Color(0xFF4A2E15),
      trayInset: Color(0xFF3A2210),
      trayGroove: Color(0xFF2E1D0E),
      bench: Color(0xFF8A5E33),
      benchDeep: Color(0xFF6E4A26),
      kraft: Color(0xFFD9BE8C),
      kraftDark: Color(0xFFC4A468),
      text: Color(0xFF2E1D0E),
      textSoft: Color(0xFF5A4326),
      accent: Color(0xFFB08A3E),
      accentLight: Color(0xFFE3C99B),
      comboRed: Color(0xFFA63A22),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFF2B950),
    ),
    WorkshopThemeDef(
      id: 'walnut',
      name: 'Walnut Workshop',
      blockLight: Color(0xFF8A5A30),
      blockMid: Color(0xFF6B4423),
      blockDark: Color(0xFF4A2E15),
      trayFrame: Color(0xFF33200F),
      trayInset: Color(0xFF241608),
      trayGroove: Color(0xFF1A0F05),
      bench: Color(0xFF6B4A28),
      benchDeep: Color(0xFF54381D),
      kraft: Color(0xFFD9BE8C),
      kraftDark: Color(0xFFC4A468),
      text: Color(0xFF241608),
      textSoft: Color(0xFF5A4326),
      accent: Color(0xFFC9A24B),
      accentLight: Color(0xFFE8D5A0),
      comboRed: Color(0xFFA63A22),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFF2B950),
    ),
    WorkshopThemeDef(
      id: 'cherry',
      name: 'Cherry Craftsman',
      blockLight: Color(0xFFC07A52),
      blockMid: Color(0xFF9C4A2F),
      blockDark: Color(0xFF6E2F1C),
      trayFrame: Color(0xFF4A1F14),
      trayInset: Color(0xFF38150D),
      trayGroove: Color(0xFF2B1009),
      bench: Color(0xFF8A5232),
      benchDeep: Color(0xFF6E3F24),
      kraft: Color(0xFFE0C491),
      kraftDark: Color(0xFFC9A96E),
      text: Color(0xFF2E1A0E),
      textSoft: Color(0xFF6B4A2E),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      comboRed: Color(0xFF96291A),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFF5C05A),
    ),
    WorkshopThemeDef(
      id: 'pine',
      name: 'Pine & Sage',
      blockLight: Color(0xFFE0C084),
      blockMid: Color(0xFFC8A96A),
      blockDark: Color(0xFF9A7A44),
      trayFrame: Color(0xFF4F5A33),
      trayInset: Color(0xFF3E4527),
      trayGroove: Color(0xFF2E3419),
      bench: Color(0xFF9A8A5A),
      benchDeep: Color(0xFF7C6E46),
      kraft: Color(0xFFE6D3A3),
      kraftDark: Color(0xFFD0B87E),
      text: Color(0xFF2E2A12),
      textSoft: Color(0xFF5F5836),
      accent: Color(0xFF8A9A4F),
      accentLight: Color(0xFFC9D69A),
      comboRed: Color(0xFFA63A22),
      sage: Color(0xFF5F7040),
      lampAmber: Color(0xFFF2D080),
    ),
    WorkshopThemeDef(
      id: 'honey',
      name: 'Honey Candy',
      proOnly: true,
      blockLight: Color(0xFFF0C05A),
      blockMid: Color(0xFFD9A441),
      blockDark: Color(0xFFA67A24),
      trayFrame: Color(0xFF5A3A14),
      trayInset: Color(0xFF452B0D),
      trayGroove: Color(0xFF332008),
      bench: Color(0xFF9A6E2E),
      benchDeep: Color(0xFF7C5622),
      kraft: Color(0xFFF0DCA0),
      kraftDark: Color(0xFFDCC084),
      text: Color(0xFF332008),
      textSoft: Color(0xFF6B4E22),
      accent: Color(0xFFE8B83A),
      accentLight: Color(0xFFFFE0A0),
      comboRed: Color(0xFFB03A1A),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFFFD070),
    ),
    WorkshopThemeDef(
      id: 'seaglass',
      name: 'Sea Glass',
      proOnly: true,
      blockLight: Color(0xFF9AC4B4),
      blockMid: Color(0xFF6E9A8A),
      blockDark: Color(0xFF4A6E62),
      trayFrame: Color(0xFF2E443E),
      trayInset: Color(0xFF22332E),
      trayGroove: Color(0xFF182420),
      bench: Color(0xFF5F7A6E),
      benchDeep: Color(0xFF4A6258),
      kraft: Color(0xFFDCE8DC),
      kraftDark: Color(0xFFBCCDBE),
      text: Color(0xFF1C2A26),
      textSoft: Color(0xFF4A5A54),
      accent: Color(0xFF8AB4A4),
      accentLight: Color(0xFFC4DED4),
      comboRed: Color(0xFFA6502A),
      sage: Color(0xFF5F7040),
      lampAmber: Color(0xFFF2D080),
    ),
    WorkshopThemeDef(
      id: 'slate',
      name: 'Slate & Iron',
      proOnly: true,
      blockLight: Color(0xFF9AA0A8),
      blockMid: Color(0xFF6E747C),
      blockDark: Color(0xFF4A4E54),
      trayFrame: Color(0xFF2E3238),
      trayInset: Color(0xFF22262B),
      trayGroove: Color(0xFF16191D),
      bench: Color(0xFF5F646C),
      benchDeep: Color(0xFF4A4E54),
      kraft: Color(0xFFD8D4C8),
      kraftDark: Color(0xFFBEB8A6),
      text: Color(0xFF1E2126),
      textSoft: Color(0xFF4E5258),
      accent: Color(0xFFA8ADB4),
      accentLight: Color(0xFFD8DCE0),
      comboRed: Color(0xFF96402A),
      sage: Color(0xFF7C8A6A),
      lampAmber: Color(0xFFE8C878),
    ),
    WorkshopThemeDef(
      id: 'ember',
      name: 'Ember Forge',
      proOnly: true,
      blockLight: Color(0xFFC87A4A),
      blockMid: Color(0xFF9A4E2A),
      blockDark: Color(0xFF6E3018),
      trayFrame: Color(0xFF3A2014),
      trayInset: Color(0xFF2A160D),
      trayGroove: Color(0xFF1E0F08),
      bench: Color(0xFF6E4530),
      benchDeep: Color(0xFF583626),
      kraft: Color(0xFFE0C491),
      kraftDark: Color(0xFFC9A96E),
      text: Color(0xFF241208),
      textSoft: Color(0xFF5F3E26),
      accent: Color(0xFFD0803A),
      accentLight: Color(0xFFF0B878),
      comboRed: Color(0xFFC03A1A),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFFFC05A),
    ),
    WorkshopThemeDef(
      id: 'moss',
      name: 'Moss & Stone',
      proOnly: true,
      blockLight: Color(0xFFA8B478),
      blockMid: Color(0xFF7C8A4F),
      blockDark: Color(0xFF565F33),
      trayFrame: Color(0xFF3E4430),
      trayInset: Color(0xFF2E3324),
      trayGroove: Color(0xFF202418),
      bench: Color(0xFF6E7050),
      benchDeep: Color(0xFF585A40),
      kraft: Color(0xFFE0D8B0),
      kraftDark: Color(0xFFC4B88C),
      text: Color(0xFF242A14),
      textSoft: Color(0xFF54563A),
      accent: Color(0xFF9AA85F),
      accentLight: Color(0xFFCDD8A0),
      comboRed: Color(0xFFA63A22),
      sage: Color(0xFF5F7040),
      lampAmber: Color(0xFFF2D080),
    ),
    WorkshopThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      proOnly: true,
      blockLight: Color(0xFF9A5A44),
      blockMid: Color(0xFF6E2F1C),
      blockDark: Color(0xFF4A1F14),
      trayFrame: Color(0xFF2E130C),
      trayInset: Color(0xFF220D07),
      trayGroove: Color(0xFF180905),
      bench: Color(0xFF6E3A24),
      benchDeep: Color(0xFF582C1B),
      kraft: Color(0xFFE8D0A0),
      kraftDark: Color(0xFFD0B480),
      text: Color(0xFF220D07),
      textSoft: Color(0xFF5F3A28),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      comboRed: Color(0xFF96291A),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFF5C05A),
    ),
    WorkshopThemeDef(
      id: 'sandstone',
      name: 'Desert Sandstone',
      proOnly: true,
      blockLight: Color(0xFFE0B878),
      blockMid: Color(0xFFC49A58),
      blockDark: Color(0xFF96703A),
      trayFrame: Color(0xFF5A4226),
      trayInset: Color(0xFF46331C),
      trayGroove: Color(0xFF332412),
      bench: Color(0xFFA8824E),
      benchDeep: Color(0xFF86683C),
      kraft: Color(0xFFF0E0B0),
      kraftDark: Color(0xFFD8C48C),
      text: Color(0xFF332412),
      textSoft: Color(0xFF6B5636),
      accent: Color(0xFFC49A58),
      accentLight: Color(0xFFE8CC94),
      comboRed: Color(0xFFA6502A),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFFFD88A),
    ),
    WorkshopThemeDef(
      id: 'midnight',
      name: 'Midnight Walnut',
      proOnly: true,
      blockLight: Color(0xFF6E5A44),
      blockMid: Color(0xFF4A3A28),
      blockDark: Color(0xFF2E2214),
      trayFrame: Color(0xFF1E160C),
      trayInset: Color(0xFF140F08),
      trayGroove: Color(0xFF0C0905),
      bench: Color(0xFF3A2E1E),
      benchDeep: Color(0xFF2C2216),
      kraft: Color(0xFFD9BE8C),
      kraftDark: Color(0xFFB89A60),
      text: Color(0xFFF0E0BC),
      textSoft: Color(0xFFC4AC7E),
      accent: Color(0xFFC9A24B),
      accentLight: Color(0xFFE8D5A0),
      comboRed: Color(0xFFC0502A),
      sage: Color(0xFF8A9A5F),
      lampAmber: Color(0xFFF2C05A),
    ),
    WorkshopThemeDef(
      id: 'bamboo',
      name: 'Bamboo Zen',
      proOnly: true,
      blockLight: Color(0xFFE8D89A),
      blockMid: Color(0xFFC4B46E),
      blockDark: Color(0xFF94824A),
      trayFrame: Color(0xFF3A3220),
      trayInset: Color(0xFF2A2416),
      trayGroove: Color(0xFF1C180E),
      bench: Color(0xFF8A7A52),
      benchDeep: Color(0xFF6E6240),
      kraft: Color(0xFFF0E8C8),
      kraftDark: Color(0xFFD8CCA0),
      text: Color(0xFF1C180E),
      textSoft: Color(0xFF5F543A),
      accent: Color(0xFF8A7A3A),
      accentLight: Color(0xFFC4B478),
      comboRed: Color(0xFF96402A),
      sage: Color(0xFF5F7040),
      lampAmber: Color(0xFFFFE09A),
    ),
    WorkshopThemeDef(
      id: 'rosewood',
      name: 'Rosewood Atelier',
      proOnly: true,
      blockLight: Color(0xFF8A4A3A),
      blockMid: Color(0xFF5F2E22),
      blockDark: Color(0xFF3E1C14),
      trayFrame: Color(0xFF2A120C),
      trayInset: Color(0xFF1E0C08),
      trayGroove: Color(0xFF140805),
      bench: Color(0xFF5F3A2A),
      benchDeep: Color(0xFF4A2C20),
      kraft: Color(0xFFE0C8A8),
      kraftDark: Color(0xFFC4A884),
      text: Color(0xFF1E0C08),
      textSoft: Color(0xFF5F4438),
      accent: Color(0xFFC08050),
      accentLight: Color(0xFFE8B488),
      comboRed: Color(0xFFB03020),
      sage: Color(0xFF7C8A4F),
      lampAmber: Color(0xFFF2B878),
    ),
  ];

  static WorkshopThemeDef byId(String id, {WorkshopThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) =>
      id != 'custom' && (byId(id).proOnly) || id == 'custom';

  /// Builds the user-designed custom theme from stored ARGB colors.
  static WorkshopThemeDef customFrom(Map<String, int> c) {
    Color col(String k, int fallback) => Color(c[k] ?? fallback);
    final block = col('block', 0xFFA9763F);
    final board = col('board', 0xFF4A2E15);
    final bench = col('bench', 0xFF8A5E33);
    final accent = col('accent', 0xFFB08A3E);
    return WorkshopThemeDef(
      id: 'custom',
      name: 'My Workshop',
      proOnly: true,
      blockLight: _mix(block, const Color(0xFFFFFFFF), 0.35),
      blockMid: block,
      blockDark: _mix(block, const Color(0xFF000000), 0.35),
      trayFrame: _mix(board, const Color(0xFF000000), 0.15),
      trayInset: _mix(board, const Color(0xFF000000), 0.35),
      trayGroove: _mix(board, const Color(0xFF000000), 0.55),
      bench: bench,
      benchDeep: _mix(bench, const Color(0xFF000000), 0.2),
      kraft: const Color(0xFFD9BE8C),
      kraftDark: const Color(0xFFC4A468),
      text: const Color(0xFF2E1D0E),
      textSoft: const Color(0xFF5A4326),
      accent: accent,
      accentLight: _mix(accent, const Color(0xFFFFFFFF), 0.4),
      comboRed: const Color(0xFFA63A22),
      sage: const Color(0xFF7C8A4F),
      lampAmber: const Color(0xFFF2B950),
    );
  }

  static Color _mix(Color a, Color b, double t) => Color.fromARGB(
        0xFF,
        ((a.r * 255.0) + ((b.r - a.r) * 255.0) * t).round().clamp(0, 255),
        ((a.g * 255.0) + ((b.g - a.g) * 255.0) * t).round().clamp(0, 255),
        ((a.b * 255.0) + ((b.b - a.b) * 255.0) * t).round().clamp(0, 255),
      );
}

/// 12 physical block materials. First 4 are FREE; the rest are PRO.
class BlockStyles {
  static const List<BlockStyleDef> all = [
    BlockStyleDef(name: 'Oak', light: Color(0xFFC89B62), mid: Color(0xFFA9763F), dark: Color(0xFF7A5227)),
    BlockStyleDef(name: 'Walnut', light: Color(0xFF8A5A30), mid: Color(0xFF6B4423), dark: Color(0xFF4A2E15)),
    BlockStyleDef(name: 'Cherry', light: Color(0xFFC07A52), mid: Color(0xFF9C4A2F), dark: Color(0xFF6E2F1C)),
    BlockStyleDef(name: 'Ash', light: Color(0xFFE0C084), mid: Color(0xFFC8A96A), dark: Color(0xFF9A7A44)),
    BlockStyleDef(name: 'Pine', light: Color(0xFFD8C878), mid: Color(0xFFB8A852), dark: Color(0xFF8A7A34), proOnly: true),
    BlockStyleDef(name: 'Honeycomb', light: Color(0xFFF0C05A), mid: Color(0xFFD9A441), dark: Color(0xFFA67A24), proOnly: true),
    BlockStyleDef(name: 'Sea Glass', light: Color(0xFF9AC4B4), mid: Color(0xFF6E9A8A), dark: Color(0xFF4A6E62), proOnly: true),
    BlockStyleDef(name: 'Slate', light: Color(0xFF9AA0A8), mid: Color(0xFF6E747C), dark: Color(0xFF4A4E54), proOnly: true),
    BlockStyleDef(name: 'Ember', light: Color(0xFFC87A4A), mid: Color(0xFF9A4E2A), dark: Color(0xFF6E3018), proOnly: true),
    BlockStyleDef(name: 'Moss Agate', light: Color(0xFFA8B478), mid: Color(0xFF7C8A4F), dark: Color(0xFF565F33), proOnly: true),
    BlockStyleDef(name: 'Marble', light: Color(0xFFE8E4DA), mid: Color(0xFFC4BEB2), dark: Color(0xFF948E82), proOnly: true),
    BlockStyleDef(name: 'Ebony', light: Color(0xFF5A4A3A), mid: Color(0xFF3A2E22), dark: Color(0xFF1E1610), proOnly: true),
  ];

  static BlockStyleDef byIndex(int i) =>
      all[i.clamp(0, all.length - 1)];

  static bool isPro(int i) => byIndex(i).proOnly;

  /// Color-blind-safe palette: 12 hues distinguishable by hue AND lightness.
  static const List<Color> colorBlind = [
    Color(0xFFD9A441), // golden
    Color(0xFF3E2A14), // dark brown
    Color(0xFFA63A22), // brick red
    Color(0xFF7C8A4F), // sage green
    Color(0xFF3E6B8A), // steel blue
    Color(0xFFE8E0C8), // ivory
    Color(0xFF8A4A6E), // plum
    Color(0xFF4A6E62), // deep teal
    Color(0xFFD0803A), // orange
    Color(0xFF5F7040), // moss
    Color(0xFF6E747C), // slate gray
    Color(0xFFC08050), // copper
  ];
}

/// 6 tray trim treatments. First 3 are FREE; the rest are PRO.
class BoardAccents {
  static const List<BoardAccentDef> all = [
    BoardAccentDef(name: 'Brass Trim', frame: Color(0xFF4A2E15), groove: Color(0xFF2E1D0E)),
    BoardAccentDef(name: 'Walnut Inlay', frame: Color(0xFF33200F), groove: Color(0xFF1A0F05)),
    BoardAccentDef(name: 'Copper Rivets', frame: Color(0xFF5F3A22), groove: Color(0xFF33200F)),
    BoardAccentDef(name: 'Iron Bands', frame: Color(0xFF2E3238), groove: Color(0xFF16191D), proOnly: true),
    BoardAccentDef(name: 'Sage Line', frame: Color(0xFF4F5A33), groove: Color(0xFF2E3419), proOnly: true),
    BoardAccentDef(name: 'Brick Edge', frame: Color(0xFF6E2F1C), groove: Color(0xFF3E1C10), proOnly: true),
  ];

  static BoardAccentDef byIndex(int i) =>
      all[i.clamp(0, all.length - 1)];

  static bool isPro(int i) => byIndex(i).proOnly;
}
