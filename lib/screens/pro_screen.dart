import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../design.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/workshop_themes.dart';
import '../widgets/wood.dart';

/// Block Fill PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final WorkshopAudio audio;
  final BlockFillSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  WorkshopThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.gameStart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy the full workshop!',
              style: Workshop.body(15, color: _t.kraft)),
          backgroundColor: _t.trayFrame,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.gameStart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Workshop.body(15, color: _t.kraft)),
        backgroundColor: _t.trayFrame,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return Scaffold(
      body: WorkbenchBackground(
        theme: t,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: Row(
                  children: [
                    WoodKnob(
                      theme: t,
                      size: 44,
                      icon: Icons.arrow_back,
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('BLOCK FILL PRO',
                          style: Workshop.burned(22, color: t.text),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: s,
                  builder: (_, _) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    child: Column(
                      children: [
                        _ComparisonCard(theme: t, isPro: s.isPro),
                        const SizedBox(height: 16),
                        _BuyCard(
                          theme: t,
                          settings: s,
                          store: store,
                          audio: widget.audio,
                        ),
                        const SizedBox(height: 16),
                        _TipsCard(
                          theme: t,
                          store: store,
                          audio: widget.audio,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final WorkshopThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete Block Fill game', true, true),
      ('Classic, Blitz & Daily modes', true, true),
      ('Full rules engine + hints', true, true),
      ('Music & workshop sound effects', true, true),
      ('Renameable carpenter profile', true, true),
      ('Workshop themes', '4', '14 + custom'),
      ('Block materials', '4', '12'),
      ('Board accents', '3', '6'),
      ('Custom workshop creator', false, true),
      ('PRO supporter badge', false, true),
    ];
    return KraftPlaque(
      theme: theme,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
      child: Column(
        children: [
          Text('Free vs PRO', style: Workshop.burned(20, color: theme.text)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: Workshop.body(13, color: theme.textSoft),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: Workshop.label(12, color: theme.textSoft),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: Workshop.label(12, color: theme.text),
                      textAlign: TextAlign.center)),
            ],
          ),
          Divider(height: 14, color: theme.kraftDark),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1,
                        style: Workshop.body(13, color: theme.text)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2, theme: theme)),
                  Expanded(flex: 2, child: _Cell(value: r.$3, theme: theme)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.accent.withValues(alpha: 0.25),
                  border: Border.all(color: theme.accentLight),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: Workshop.label(14, color: theme.text)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  final WorkshopThemeDef theme;
  const _Cell({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: Workshop.body(15,
            color: v
                ? theme.sage
                : theme.textSoft.withValues(alpha: 0.4)),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: Workshop.label(12, color: theme.text),
      textAlign: TextAlign.center,
    );
  }
}

class _BuyCard extends StatelessWidget {
  final WorkshopThemeDef theme;
  final BlockFillSettings settings;
  final StoreService store;
  final WorkshopAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
    return KraftPlaque(
      theme: theme,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
      child: Column(
        children: [
          Text('Unlock PRO', style: Workshop.burned(20, color: theme.text)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text('You already own PRO — thank you!',
                style: Workshop.body(14, color: theme.text),
                textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Workshop.body(14, color: theme.textSoft),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(
                pro.description.isNotEmpty
                    ? pro.description
                    : 'Unlock the full workshop, forever.',
                style: Workshop.body(14, color: theme.text),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => OakButton(
                theme: theme,
                label: busy ? 'Working…' : 'Get PRO — ${pro.price}',
                width: 260,
                fontSize: 18,
                onTap: busy
                    ? () {}
                    : () {
                        audio.click();
                        store.buyPro();
                      },
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: Workshop.body(13, color: theme.comboRed),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              audio.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: Workshop.label(13, color: theme.textSoft)),
          ),
        ],
      ),
    );
  }
}

/// Consumable tips — pure support, with real store prices.
class _TipsCard extends StatelessWidget {
  final WorkshopThemeDef theme;
  final StoreService store;
  final WorkshopAudio audio;
  const _TipsCard({
    required this.theme,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return KraftPlaque(
      theme: theme,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
      child: Column(
        children: [
          Text('Tip the Maker', style: Workshop.burned(20, color: theme.text)),
          const SizedBox(height: 8),
          Text(
            'Block Fill is free forever. A small tip keeps new games coming!',
            style: Workshop.body(14, color: theme.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Workshop.body(13, color: theme.textSoft),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: Workshop.body(13, color: theme.textSoft))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    theme: theme,
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final WorkshopThemeDef theme;
  final String label;
  final VoidCallback onTap;
  const _TipChip({
    required this.theme,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withValues(alpha: 0.25),
          border: Border.all(
              color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: Workshop.label(14, color: theme.text)),
      ),
    );
  }
}
