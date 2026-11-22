import 'package:flutter/material.dart';

import 'app_language.dart';
import 'menti_animation_player.dart';
import 'menti_life_events.dart';
import 'menti_alive_preview.dart';

/// REVIEW controls are placed in normal document flow, never over journal UI.
class MentiHomeReviewFeedback extends StatelessWidget {
  const MentiHomeReviewFeedback({super.key});
  @override
  Widget build(BuildContext context) {
    final session = MentiAnimationScope.of(context)!;
    final h = session.home!, c = session.controller;
    final s = appStrings(context);
    return ListenableBuilder(
      listenable: Listenable.merge([h, c]),
      builder: (context, _) {
        final message = h.wink
            ? s.homeWinkReply
            : switch (h.event) {
                MentiLifeEvent.journalSaved => s.homeSavedReply,
                MentiLifeEvent.xpEarned => s.homeXpReply,
                MentiLifeEvent.xpMilestone => s.homeLevelReply,
                MentiLifeEvent.appOpened => s.homeWelcomeReply,
                null => s.homeReviewHint,
                _ => s.homeEncourageReply,
              };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REVIEW',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    key: const ValueKey('home-reaction-message'),
                  ),
                ),
                Text(
                  c.active != null ? s.homeReviewVideo : s.homeReviewStill,
                  key: const ValueKey('home-reaction-media'),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      key: const ValueKey('home-wink'),
                      onPressed: h.requestWink,
                      icon: const Icon(Icons.face),
                      label: Text(s.lifeWink),
                    ),
                    TextButton.icon(
                      key: const ValueKey('home-stop'),
                      onPressed: c.stop,
                      icon: const Icon(Icons.stop),
                      label: Text(s.aliveStop),
                    ),
                    TextButton.icon(
                      key: const ValueKey('home-animation-studio'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MentiAlivePreviewPage(
                            developerPreview: true,
                            studioMode: true,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.movie_outlined),
                      label: Text(s.studioTitle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
