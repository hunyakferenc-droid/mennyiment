import 'package:flutter/material.dart';

import 'app_language.dart';
import 'l10n/generated/app_localizations.dart';
import 'menti_animation_player.dart';
import 'menti_animation_controller.dart';
import 'menti_collection_widgets.dart';
import 'menti_collection_model.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_motion.dart';
import 'menti_experience_settings.dart';
import 'menti_reaction_engine.dart';

String mentiLifeReactionLabel(AppLocalizations s, MentiLifeReaction r) =>
    switch (r) {
      MentiLifeReaction.welcome => s.lifeWelcome,
      MentiLifeReaction.blink => s.lifeBlink,
      MentiLifeReaction.wink => s.lifeWink,
      MentiLifeReaction.smile => s.lifeSmile,
      MentiLifeReaction.joy => s.lifeJoy,
      MentiLifeReaction.congratulation => s.lifeCongratulation,
      MentiLifeReaction.victoryDance => s.lifeVictoryDance,
      MentiLifeReaction.thinking => s.lifeThinking,
      MentiLifeReaction.surprise => s.lifeSurprise,
      MentiLifeReaction.encouragement => s.lifeEncouragement,
      MentiLifeReaction.empathy => s.lifeEmpathy,
      MentiLifeReaction.breathing => s.lifeBreathing,
      MentiLifeReaction.rest => s.lifeRest,
      MentiLifeReaction.milestone => s.lifeMilestone,
    };

class MentiAnimationPreviewPage extends StatefulWidget {
  const MentiAnimationPreviewPage({super.key});
  @override
  State<MentiAnimationPreviewPage> createState() =>
      _MentiAnimationPreviewPageState();
}

class _MentiAnimationPreviewPageState extends State<MentiAnimationPreviewPage> {
  final _scroll = ScrollController();
  Future<void> _tryReaction(
    MentiAnimationController c,
    MentiLifeReaction r,
  ) async {
    // Reaction controls may be below the character on a narrow screen.
    // Bring the actual saved character back into view before requesting video.
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        0,
        duration: MentiMotionScope.reducedOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) c.request(r, token: 'preview-${r.name}', manual: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context), session = MentiAnimationScope.of(context);
    final complete = CompleteLookScope.of(context);
    final look = complete?.ready == true && complete!.selection.active
        ? CompleteLook.find(complete.selection.lookId)
        : null;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.lifeTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(s.lifeNoClip),
        ),
      );
    }
    final c = session.controller, prefs = session.settings;
    return ListenableBuilder(
      listenable: Listenable.merge([c, prefs]),
      builder: (context, _) {
        final motion =
            MentiMotionScope.animateOf(context) &&
            MentiExperienceScope.reactionsOf(context);
        final approved = look == null
            ? 0
            : c.catalog.clips
                  .where((v) => v.playable && v.lookId == look.id)
                  .length;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
                ? 104
                : kToolbarHeight,
            title: Text(s.lifeTitle),
          ),
          body: SafeArea(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                Text(s.lifeIntro),
                const SizedBox(height: 12),
                Center(
                  child: look == null
                      ? const MentiCurrentAvatar(
                          size: 200,
                          legacyChild: SizedBox.shrink(),
                        )
                      : MentiAnimationPlayer(look: look, size: 220),
                ),
                if (look != null)
                  Text(
                    look.name(context),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                Text(
                  look == null ? s.lifeLegacy : s.lifeApprovedCount(approved),
                ),
                if (approved == 0) Text(s.lifeNoClip),
                if (!motion) Text(s.lifeReduced),
                if (c.status == MentiPlaybackStatus.loading)
                  Text(s.lifeLoading),
                if (c.status == MentiPlaybackStatus.error)
                  Semantics(liveRegion: true, child: Text(s.lifePlaybackError)),
                if (prefs.error != null) ...[
                  Text(s.lifeSettingsError),
                  TextButton(
                    onPressed: prefs.saving ? null : prefs.load,
                    child: Text(s.restoreRetry),
                  ),
                ],
                SwitchListTile.adaptive(
                  key: const ValueKey('life-enabled'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.lifeEnabled),
                  value: prefs.ready && prefs.value.enabled,
                  onChanged: prefs.ready && !prefs.saving
                      ? (v) => prefs.save(
                          enabled: v,
                          frequency: prefs.value.frequency,
                        )
                      : null,
                ),
                Text(
                  s.lifeFrequency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in MentiAnimationFrequency.values)
                      ChoiceChip(
                        key: ValueKey('life-frequency-${f.name}'),
                        label: Text(switch (f) {
                          MentiAnimationFrequency.low => s.lifeLow,
                          MentiAnimationFrequency.normal => s.lifeNormal,
                          MentiAnimationFrequency.frequent => s.lifeFrequent,
                        }),
                        selected: prefs.value.frequency == f,
                        onSelected: prefs.ready && !prefs.saving
                            ? (_) => prefs.save(
                                enabled: prefs.value.enabled,
                                frequency: f,
                              )
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s.lifeFrequencyHint),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('life-static'),
                  onPressed: () => c.stop(),
                  icon: const Icon(Icons.pause_circle_outline),
                  label: Text(s.lifeStatic),
                ),
                for (final r in MentiLifeReaction.values)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            mentiLifeReactionLabel(s, r),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (look == null ||
                              c.catalog.find(look.id, r) == null)
                            Text(s.lifeUnavailable),
                          Semantics(
                            identifier: 'life-reaction-${r.name}',
                            label: mentiLifeReactionLabel(s, r),
                            child: OutlinedButton.icon(
                              key: ValueKey('life-reaction-${r.name}'),
                              onPressed:
                                  look != null &&
                                      motion &&
                                      prefs.ready &&
                                      prefs.value.enabled &&
                                      c.catalog.find(look.id, r) != null
                                  ? () => _tryReaction(c, r)
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(s.lifeTry),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
