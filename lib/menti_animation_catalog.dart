import 'data_backup.dart';
import 'menti_collection_model.dart';
import 'menti_reaction_engine.dart';

/// Only reviewed local media can become playable. URLs belong in the docs ledger.
class MentiAnimationClip {
  const MentiAnimationClip({
    required this.id,
    required this.lookId,
    required this.reaction,
    required this.asset,
    required this.sha256,
    required this.bytes,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.version,
    required this.approvedBy,
    required this.approvedAt,
    required this.rightsVerified,
    required this.identityVerified,
    required this.backgroundApproved,
  });
  final String id, lookId, asset, sha256, approvedBy, approvedAt;
  final MentiLifeReaction reaction;
  final int bytes, durationMs, width, height, version;
  final bool rightsVerified, identityVerified, backgroundApproved;
  bool get playable =>
      rightsVerified &&
      identityVerified &&
      backgroundApproved &&
      approvedBy.trim().isNotEmpty;
  factory MentiAnimationClip.fromJson(Map<String, dynamic> j) {
    void need(bool ok) {
      if (!ok) throw const FormatException('Unsupported animation media');
    }

    for (final key in [
      'id',
      'lookId',
      'reaction',
      'asset',
      'sha256',
      'approvedBy',
      'approvedAt',
    ]) {
      need(j[key] is String);
    }
    for (final key in ['bytes', 'durationMs', 'width', 'height', 'version']) {
      need(j[key] is int);
    }
    need(CompleteLook.find(j['lookId']) != null);
    need(MentiLifeReaction.values.any((r) => r.name == j['reaction']));
    need(
      RegExp(r'^assets/menti_life/clips/[a-zA-Z0-9_-]+\.(mp4|webm)$')
          .hasMatch(j['asset']),
    );
    need(RegExp(r'^[0-9a-f]{64}$').hasMatch(j['sha256']));
    need(
      j['bytes'] > 0 &&
          j['bytes'] <= 6 * 1024 * 1024 &&
          j['durationMs'] > 0 &&
          j['durationMs'] <= 8000,
    );
    need(
      j['width'] > 0 &&
          j['width'] <= 720 &&
          j['height'] > 0 &&
          j['height'] <= 960,
    );
    need((j['width'] / j['height'] - .75).abs() < .01 && j['version'] >= 1);
    need(
      j['approvedBy'].trim().isNotEmpty &&
          DateTime.tryParse(j['approvedAt']) != null,
    );
    need(
      j['rightsVerified'] == true &&
          j['identityVerified'] == true &&
          j['backgroundApproved'] == true &&
          j['audio'] == false,
    );
    return MentiAnimationClip(
      id: j['id'],
      lookId: j['lookId'],
      reaction: MentiLifeReaction.values.byName(j['reaction']),
      asset: j['asset'],
      sha256: j['sha256'],
      bytes: j['bytes'],
      durationMs: j['durationMs'],
      width: j['width'],
      height: j['height'],
      version: j['version'],
      approvedBy: j['approvedBy'],
      approvedAt: j['approvedAt'],
      rightsVerified: true,
      identityVerified: true,
      backgroundApproved: true,
    );
  }
}

class MentiAnimationCatalog {
  const MentiAnimationCatalog([this.clips = const []]);
  final List<MentiAnimationClip> clips;
  factory MentiAnimationCatalog.decode(String raw) {
    final j = decodeBackupJson(raw);
    if (j is! Map<String, dynamic> ||
        j['version'] != 1 ||
        j['clips'] is! List) {
      throw const FormatException('Unknown animation catalog');
    }
    final clips = <MentiAnimationClip>[];
    final ids = <String>{};
    for (final value in j['clips']) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid clip');
      }
      final clip = MentiAnimationClip.fromJson(value);
      if (!ids.add(clip.id)) {
        throw const FormatException('Duplicate animation ID');
      }
      clips.add(clip);
    }
    return MentiAnimationCatalog(List.unmodifiable(clips));
  }
  MentiAnimationClip? find(String look, MentiLifeReaction reaction) {
    final candidates =
        clips
            .where(
              (c) => c.playable && c.lookId == look && c.reaction == reaction,
            )
            .toList()
          ..sort((a, b) => b.version.compareTo(a.version));
    return candidates.isEmpty ? null : candidates.first;
  }
}
