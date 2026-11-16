import 'menti_animation_catalog.dart';
import 'menti_collection_model.dart';
import 'menti_reaction_engine.dart';

/// Read-only inventory. Availability is never permission for production playback.
enum MentiStudioStatus { missing, reviewRequired, approved }

class MentiStudioSlot {
  const MentiStudioSlot(this.look, this.reaction, this.status, this.clip);
  final CompleteLook look;
  final MentiLifeReaction reaction;
  final MentiStudioStatus status;
  final MentiAnimationClip? clip;
}

class MentiStudioInventory {
  const MentiStudioInventory({
    this.production = const MentiAnimationCatalog(),
    this.review = const MentiAnimationCatalog(),
  });
  final MentiAnimationCatalog production, review;
  static const families = ['girl', 'neutral', 'boy'];
  static List<CompleteLook> get looks => [
    for (final family in families)
      ...CompleteLook.all.where((look) => look.family == family),
  ];
  MentiStudioSlot slot(CompleteLook look, MentiLifeReaction reaction) {
    final approved = production.find(look.id, reaction);
    if (approved != null && approved.playable) {
      return MentiStudioSlot(
        look,
        reaction,
        MentiStudioStatus.approved,
        approved,
      );
    }
    final candidates =
        review.clips
            .where(
              (clip) => clip.lookId == look.id && clip.reaction == reaction,
            )
            .toList()
          ..sort((a, b) => b.version.compareTo(a.version));
    return MentiStudioSlot(
      look,
      reaction,
      candidates.isEmpty
          ? MentiStudioStatus.missing
          : MentiStudioStatus.reviewRequired,
      candidates.isEmpty ? null : candidates.first,
    );
  }

  List<MentiStudioSlot> get slots => [
    for (final look in looks)
      for (final reaction in MentiLifeReaction.values) slot(look, reaction),
  ];
  int count(MentiStudioStatus status) =>
      slots.where((s) => s.status == status).length;
}

/// Explicit REVIEW adapter; the normal app never constructs this catalog.
class MentiStudioPlaybackCatalog extends MentiAnimationCatalog {
  MentiStudioPlaybackCatalog(this.production, this.review)
    : super(List.unmodifiable([...production.clips, ...review.clips]));
  final MentiAnimationCatalog production, review;
  @override
  MentiAnimationClip? find(String look, MentiLifeReaction reaction) =>
      production.find(look, reaction) ?? review.find(look, reaction);
}
