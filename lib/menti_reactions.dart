
import 'package:flutter/material.dart';
import 'menti_motion.dart';
import 'app_language.dart';
import 'menti_experience_settings.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_identity/menti_identity_controller.dart';

enum MentiMood {
  welcome,
  drinkAdded,
  statistics,
  goals,
  dailyCheckIn,
  weeklyCompleted,
  levelUp,
  alcoholFreeEntry,
  challengeCompleted,
  personalGoalCompleted,
}

class MentiReactions {
  // Presentation-only catalog. Callers choose an event only after a confirmed
  // save; this class never reads preferences, grants XP or infers missing days.
  static const Map<MentiMood, List<String>> _hu = {
    MentiMood.welcome: [
      'Szia! 🍊 Jó, hogy itt vagy!',
      'Na, hogy telt a napod? 💜',
      'Menti szolgálatban. A napló a tiéd! 😎',
    ],
    MentiMood.drinkAdded: [
      'Feljegyeztem! 📝',
      'Megvan! Köszönöm, hogy rögzítetted. 💜',
      'Frissült a naplód! 🍊',
    ],
    MentiMood.statistics: [
      'Nézzük, mit mutatnak a számok! 📊',
      'Az adatok segíthetnek felismerni a szokásaidat.',
      'Menti számol. A döntés a tiéd! 💜',
    ],
    MentiMood.goals: [
      'A saját tempód a fontos! 🎯',
      'A kis lépések is számítanak. 🌱',
      'A céljaidat te határozod meg! 💜',
    ],
    MentiMood.dailyCheckIn: [
      'Mai önellenőrzés: pipa. Menti figyel! 🍊',
      'Egy perc magadra. Ez is számít. 💜',
    ],
    MentiMood.weeklyCompleted: [
      'Heti feladat kész. Menti képzeletben pacsizik! ✋',
      'Újabb tudatos lépés feljegyezve. 🌱',
    ],
    MentiMood.levelUp: [
      'Új Menti-szint! A sapka marad, a tapasztalat nő. 💜',
      'Szintet léptél a tudatos követéssel! 🍊',
    ],
    MentiMood.challengeCompleted: [
      'Heti kihívás teljesítve. Menti képzeletben pacsizik! ✋',
      'Megvan a vállalt napok száma. A sapkám megemelem! 💜',
    ],
    MentiMood.personalGoalCompleted: [
      'Elérted a heti önellenőrzési célodat. Menti bólogat! 🍊',
      'Időt szántál magadra: a heti cél teljesült. 💜',
    ],
    MentiMood.alcoholFreeEntry: [
      'Alkoholmentes ital feljegyezve. Menti bólint! 🍊',
      'Megvan a 0%-os bejegyzés. 📝',
    ],
  };

  static const Map<MentiMood, List<String>> _en = {
    MentiMood.welcome: [
      'Hi! 🍊 Good to see you!',
      'How has your day been? 💜',
      'Menti on duty. Your journal, your call! 😎',
    ],
    MentiMood.drinkAdded: [
      'Noted! 📝',
      'Saved! Thanks for recording it. 💜',
      'Your journal is up to date! 🍊',
    ],
    MentiMood.statistics: [
      'Let’s see what the numbers say! 📊',
      'Your records can help you notice patterns.',
      'Menti counts. You decide! 💜',
    ],
    MentiMood.goals: [
      'Your own pace matters! 🎯',
      'Small steps count too. 🌱',
      'You choose your goals! 💜',
    ],
    MentiMood.dailyCheckIn: [
      'Daily check-in: done. Menti is listening! 🍊',
      'A minute for yourself. That counts too. 💜',
    ],
    MentiMood.weeklyCompleted: [
      'Weekly task done. Imaginary Menti high five! ✋',
      'Another mindful step recorded. 🌱',
    ],
    MentiMood.levelUp: [
      'New Menti level! Same hat, more experience. 💜',
      'You levelled up through mindful tracking! 🍊',
    ],
    MentiMood.challengeCompleted: [
      'Weekly challenge complete. Imaginary Menti high five! ✋',
      'You reached your chosen number of days. Hats off! 💜',
    ],
    MentiMood.personalGoalCompleted: [
      'Weekly check-in goal reached. Menti nods! 🍊',
      'You made time for yourself: weekly goal complete. 💜',
    ],
    MentiMood.alcoholFreeEntry: [
      'Alcohol-free drink recorded. Menti nods! 🍊',
      'Your 0% entry is saved. 📝',
    ],
  };

  static String message(MentiMood mood, {int index = 0, String locale = 'hu'}) {
    final messages = (locale == 'en' ? _en : _hu)[mood]!;
    return messages[index % messages.length];
  }
}

/// Shared presentation for verified events; never creates an event or reward.
class MentiReactionCard extends StatelessWidget {
  const MentiReactionCard({super.key, required this.mood, this.index = 0, this.bubbleKey, this.eventToken});
  final MentiMood mood;
  final int index;
  final Key? bubbleKey;
  final Object? eventToken;

  @override
  Widget build(BuildContext context) => MentiReactionVisibility(
    token: eventToken ?? (mood, index), child: TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MentiMotionScope.reducedOf(context) ? Duration.zero
        : const Duration(milliseconds: 200),
    builder: (context, value, child) => Opacity(opacity: value, child: child),
    child: Semantics(liveRegion: true, child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (MentiIdentityScope.of(context)?.ready == true)
            MentiCurrentAvatar(size: 80, reaction: switch (mood) {
              MentiMood.drinkAdded || MentiMood.statistics || MentiMood.goals => 'focused',
              MentiMood.welcome => 'motivating', _ => 'personality',
            }, legacyChild: const SizedBox.shrink()),
          Text(appStrings(context).reactionTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          MentiSpeechBubble(key: bubbleKey, message: MentiReactions.message(mood,
            index: index, locale: Localizations.localeOf(context).languageCode)),
        ])),
    )),
  ));
}

class MentiSpeechBubble extends StatelessWidget {
  const MentiSpeechBubble({
    super.key,
    required this.message,
    this.eventToken,
  });

  final String message;
  final Object? eventToken;

  @override
  Widget build(BuildContext context) {
    return MentiReactionVisibility(token: eventToken ?? message, child: AnimatedSwitcher(
      duration: MentiMotionScope.animateOf(context)
          ? const Duration(milliseconds: 350)
          : Duration.zero,
      child: Container(
        key: ValueKey(message),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF302044),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFB68AFF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9D55FF).withValues(alpha: 0.15),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ));
  }
}
