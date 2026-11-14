// Developer-only real decoder probe. Geometric test pattern, never an app
// character or a production catalog entry. Build explicitly with --target.
import 'package:flutter/material.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_animation_player.dart';
import 'package:mennyiment/menti_collection_model.dart';
import 'package:mennyiment/menti_collection_widgets.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_reaction_engine.dart';

void main() => runApp(const DecoderProbe());

class DecoderProbe extends StatefulWidget {
  const DecoderProbe({super.key});
  @override
  State<DecoderProbe> createState() => _DecoderProbeState();
}

class _DecoderProbeState extends State<DecoderProbe> {
  late final c = MentiAnimationController(
    catalog: MentiAnimationCatalog([
      const MentiAnimationClip(
        id: 'geometric-fixture-only',
        lookId: 'boy-base-v1',
        reaction: MentiLifeReaction.wink,
        asset: 'assets/menti_life/clips/decoder_probe.mp4',
        sha256:
            '27afebc3bd398f7629bdc8386f999cb8e1cfad5103463779ebb99c84a55bf610',
        bytes: 71468,
        durationMs: 4000,
        width: 180,
        height: 240,
        version: 1,
        approvedBy: 'synthetic-fixture-only-not-character-approval',
        approvedAt: '2026-11-14',
        rightsVerified: true,
        identityVerified: true,
        backgroundApproved: true,
      ),
    ]),
  );
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (ctx, child) => MentiMotionScope(
      child: CompleteLookScope(
        child: MentiAnimationScope(controller: c, child: child!),
      ),
    ),
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Decoder probe • geometric fixture only'),
      ),
      body: ListenableBuilder(
        listenable: c,
        builder: (ctx, _) => Column(
          children: [
            MentiAnimationPlayer(look: CompleteLook.all.first, size: 180),
            Text('status:${c.status.name}'),
            Text(
              'look:${c.lookId} motion:${MentiMotionScope.animateOf(ctx)} '
              'saved:${CompleteLookScope.of(ctx)?.ready} '
              'active:${CompleteLookScope.of(ctx)?.selection.active} '
              'prefs:${MentiAnimationScope.of(ctx)?.settings.ready}',
            ),
            Text('surface:${c.handle?.frameVisible == true}'),
            Text(
              'volume:${c.handle is LocalMentiVideo ? (c.handle as LocalMentiVideo).video.value.volume : -1}',
            ),
            Text('measurements:${c.measurements.length}'),
            FilledButton(
              onPressed: () => c.request(
                MentiLifeReaction.wink,
                token: 'manual-probe',
                manual: true,
              ),
              child: const Text('Play probe'),
            ),
            OutlinedButton(onPressed: c.stop, child: const Text('Stop probe')),
          ],
        ),
      ),
    ),
  );
}
