import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'design.dart';

/// Block Fill — Carpenter's Workshop edition.
/// Stitch is the visual source of truth (stitch-batch5/blockfill/DESIGN.md).
/// Rules are authoritative from stitch-batch5/blockfill/RULES.md.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final settings = BlockFillSettings();
  await settings.load();
  final audio = WorkshopAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    musicVolume: settings.musicVolume,
    sfxVolume: settings.sfxVolume,
  );
  final store = StoreService();
  runApp(BlockFillApp(settings: settings, audio: audio, store: store));
}

class BlockFillApp extends StatefulWidget {
  final BlockFillSettings settings;
  final WorkshopAudio audio;
  final StoreService store;
  const BlockFillApp({
    super.key,
    required this.settings,
    required this.audio,
    required this.store,
  });

  @override
  State<BlockFillApp> createState() => _BlockFillAppState();
}

class _BlockFillAppState extends State<BlockFillApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep audio in sync when settings change.
    widget.settings.addListener(_syncAudio);
  }

  void _syncAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      musicVolume: widget.settings.musicVolume,
      sfxVolume: widget.settings.sfxVolume,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_syncAudio);
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final t = widget.settings.theme;
        return MaterialApp(
          title: 'Block Fill',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: t.bench,
            colorScheme: ColorScheme.light(
              primary: t.blockMid,
              onPrimary: t.text,
              surface: t.kraft,
              onSurface: t.text,
            ),
            textTheme: TextTheme(
              displayLarge: Workshop.burned(34, color: t.text),
              titleLarge: Workshop.burned(24, color: t.text),
              bodyLarge: Workshop.body(16, color: t.text),
              labelLarge: Workshop.label(13, color: t.text),
            ),
          ),
          home: SplashScreen(
            audio: widget.audio,
            settings: widget.settings,
            store: widget.store,
          ),
        );
      },
    );
  }
}
