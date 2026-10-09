import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio.dart';
import 'design.dart';
import 'scores.dart';
import 'screens/menu_screen.dart';

/// Block Fill — Carpenter's Workshop edition.
/// Stitch is the visual source of truth (stitch-batch5/blockfill/DESIGN.md).
/// Rules are authoritative from stitch-batch5/blockfill/RULES.md.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Sound.I.init();
  await ScoreStore.I.load();
  runApp(const BlockFillApp());
}

class BlockFillApp extends StatelessWidget {
  const BlockFillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Fill',
      debugShowCheckedModeBanner: false,
      theme: Workshop.theme(),
      home: const MenuScreen(),
    );
  }
}
