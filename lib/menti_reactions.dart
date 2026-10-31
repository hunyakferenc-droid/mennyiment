
import 'package:flutter/material.dart';

enum MentiMood {
  welcome,
  drinkAdded,
  statistics,
  goals,
}

class MentiReactions {
  static const Map<MentiMood, List<String>> _messages = {
    MentiMood.welcome: [
      'Szia! 🍊 Jó, hogy itt vagy!',
      'Na, hogy telt a napod? 💜',
      'Készen állok! Nézzük a naplódat! 😎',
    ],
    MentiMood.drinkAdded: [
      'Feljegyeztem! 📝',
      'Megvan! Köszönöm, hogy rögzítetted. 💜',
      'Frissült a naplód! 🍊',
    ],
    MentiMood.statistics: [
      'Nézzük, mit mutatnak a számok! 📊',
      'Az adatok segíthetnek felismerni a szokásaidat.',
      'Minden naplózott adat számít! 💜',
    ],
    MentiMood.goals: [
      'A saját tempód a fontos! 🎯',
      'A kis lépések is számítanak. 🌱',
      'A céljaidat te határozod meg! 💜',
    ],
  };

  static String message(MentiMood mood, {int index = 0}) {
    final messages = _messages[mood]!;
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
      duration: const Duration(milliseconds: 350),
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
