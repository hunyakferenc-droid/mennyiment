
import 'package:flutter/material.dart';
import 'menti_motion.dart';

enum MentiMood {
  welcome,
  drinkAdded,
  statistics,
  goals,
  dailyCheckIn,
  weeklyCompleted,
  levelUp,
  alcoholFreeEntry,
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

class MentiSpeechBubble extends StatelessWidget {
  const MentiSpeechBubble({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
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
    );
  }
}
