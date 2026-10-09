// Verifies Block Fill player-name persistence is order-safe.
//
// Block Fill keeps a single player name, persisted with
// SharedPreferences.setString('bf_player_name') — a plain string, so there
// is no StringSet-ordering hazard (unlike setStringList, which Android backs
// with an unordered StringSet and scrambled multi-name order in Ludo).
// These tests lock in that the single-string storage round-trips through a
// real SharedPreferences instance untouched: load -> rename -> fresh reload.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blockfill/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('player name persistence', () {
    test('name round-trips through storage untouched', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final s = BlockFillSettings();
      await s.load();
      expect(s.playerName, 'Carpenter'); // default before any rename

      await s.setPlayerName('  Sawdust Sam  ');
      expect(s.playerName, 'Sawdust Sam'); // trimmed by setPlayerName

      // Fresh instance = app restart: the persisted name must come back
      // exactly, never reordered/mangled.
      final reloaded = BlockFillSettings();
      await reloaded.load();
      expect(reloaded.playerName, 'Sawdust Sam');
    });

    test('empty rename falls back to the default name', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final s = BlockFillSettings();
      await s.load();

      await s.setPlayerName('   ');
      expect(s.playerName, 'Carpenter');

      final reloaded = BlockFillSettings();
      await reloaded.load();
      expect(reloaded.playerName, 'Carpenter');
    });

    test('unicode and long names persist verbatim', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final s = BlockFillSettings();
      await s.load();

      const tricky = '🪵 Wajiha the Magnificent Carpenter 3000';
      await s.setPlayerName(tricky);
      final reloaded = BlockFillSettings();
      await reloaded.load();
      expect(reloaded.playerName, tricky);
    });
  });
}
