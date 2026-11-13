/// Presentation only: stored reaction IDs and personal face choices are intact.
/// A reaction has a durable still frame, independent of the animation timers.
class MentiExpression {
  const MentiExpression(this.eyes, this.face);
  final String eyes, face;
  static MentiExpression? forReaction(String? id) => switch (id) {
    'proud' ||
    'motivating' ||
    'celebrating' ||
    'funny' => const MentiExpression('joyful', 'cheerful'),
    'focused' => const MentiExpression('attentive', 'confident'),
    'calming' || 'sleepy' => const MentiExpression('supportive', 'calm'),
    _ => null,
  };
}
