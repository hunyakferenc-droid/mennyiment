import 'data_backup.dart';
import 'menti_animation_catalog.dart';
import 'menti_collection_model.dart';
import 'menti_reaction_engine.dart';

/// Explicit developer-only adapter. Candidate flags remain false; the ordinary
/// catalog cannot select these clips. This file is not imported by main.dart.
class MentiAliveReviewCatalog extends MentiAnimationCatalog {
  const MentiAliveReviewCatalog(super.clips, {this.developerPreview = false});
  final bool developerPreview;

  factory MentiAliveReviewCatalog.decode(
    String raw, {
    bool developerPreview = false,
  }) {
    final decoded = decodeBackupJson(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid review catalog');
    }
    final j = decoded;
    void need(bool value) {
      if (!value) throw const FormatException('Invalid review media');
    }

    need(
      j['version'] == 1 &&
          j['previewOnly'] == true &&
          j['status'] == 'reviewRequired' &&
          j['clips'] is List,
    );
    final clips = <MentiAnimationClip>[];
    final ids = <String>{};
    final assetOwners = <String, String>{};
    final hashOwners = <String, String>{};
    final jobOwners = <String, String>{};
    for (final x in j['clips']) {
      need(x is Map<String, dynamic>);
      for (final key in [
        'id',
        'lookId',
        'reaction',
        'asset',
        'sha256',
        'sourceJobId',
      ]) {
        need(x[key] is String && (x[key] as String).isNotEmpty);
      }
      for (final key in ['width', 'height', 'bytes', 'durationMs', 'version']) {
        need(x[key] is int && x[key] > 0);
      }
      need(ids.add(x['id']));
      need(CompleteLook.find(x['lookId']) != null);
      need(MentiLifeReaction.values.any((r) => r.name == x['reaction']));
      need(
        RegExp(r'^assets/menti_life/clips/alive-review-[a-z_-]+-v[0-9]+\.mp4$')
            .hasMatch(x['asset']),
      );
      need(RegExp(r'^[0-9a-f]{64}$').hasMatch(x['sha256']));
      final owner = x['lookId'] as String;
      final asset = x['asset'] as String, hash = x['sha256'] as String;
      need(!assetOwners.containsKey(asset) || assetOwners[asset] == owner);
      need(!hashOwners.containsKey(hash) || hashOwners[hash] == owner);
      assetOwners[asset] = owner;
      hashOwners[hash] = owner;
      need(RegExp(r'^[0-9a-f-]{36}
      need(
        x['width'] <= 720 &&
            x['height'] <= 960 &&
            (x['width'] / x['height'] - .75).abs() < .01,
      );
      need(x['bytes'] <= 6 * 1024 * 1024 && x['durationMs'] <= 8000);
      need(
        x['audio'] == false &&
            x['previewOnly'] == true &&
            x['status'] == 'reviewRequired',
      );
      for (final key in [
        'rightsVerified',
        'identityVerified',
        'backgroundApproved',
        'ownerApproved',
      ]) {
        need(x[key] == false);
      }
      need(x['approvedBy'] == '' && x['approvedAt'] == '');
      clips.add(
        MentiAnimationClip(
          id: x['id'],
          lookId: x['lookId'],
          reaction: MentiLifeReaction.values.byName(x['reaction']),
          asset: x['asset'],
          sha256: x['sha256'],
          bytes: x['bytes'],
          durationMs: x['durationMs'],
          width: x['width'],
          height: x['height'],
          version: x['version'],
          approvedBy: '',
          approvedAt: '',
          rightsVerified: false,
          identityVerified: false,
          backgroundApproved: false,
        ),
      );
    }
    return MentiAliveReviewCatalog(
      List.unmodifiable(clips),
      developerPreview: developerPreview,
    );
  }

  @override
  MentiAnimationClip? find(String look, MentiLifeReaction reaction) {
    if (!developerPreview) return null;
    final matches =
        clips.where((c) => c.lookId == look && c.reaction == reaction).toList()
          ..sort((a, b) => b.version.compareTo(a.version));
    return matches.isEmpty ? null : matches.first;
  }
}
).hasMatch(x['sourceJobId']));
      final jobId = x['sourceJobId'] as String;
      need(!jobOwners.containsKey(jobId) || jobOwners[jobId] == owner);
      jobOwners[jobId] = owner;
      need(
        x['width'] <= 720 &&
            x['height'] <= 960 &&
            (x['width'] / x['height'] - .75).abs() < .01,
      );
      need(x['bytes'] <= 6 * 1024 * 1024 && x['durationMs'] <= 8000);
      need(
        x['audio'] == false &&
            x['previewOnly'] == true &&
            x['status'] == 'reviewRequired',
      );
      for (final key in [
        'rightsVerified',
        'identityVerified',
        'backgroundApproved',
        'ownerApproved',
      ]) {
        need(x[key] == false);
      }
      need(x['approvedBy'] == '' && x['approvedAt'] == '');
      clips.add(
        MentiAnimationClip(
          id: x['id'],
          lookId: x['lookId'],
          reaction: MentiLifeReaction.values.byName(x['reaction']),
          asset: x['asset'],
          sha256: x['sha256'],
          bytes: x['bytes'],
          durationMs: x['durationMs'],
          width: x['width'],
          height: x['height'],
          version: x['version'],
          approvedBy: '',
          approvedAt: '',
          rightsVerified: false,
          identityVerified: false,
          backgroundApproved: false,
        ),
      );
    }
    return MentiAliveReviewCatalog(
      List.unmodifiable(clips),
      developerPreview: developerPreview,
    );
  }

  @override
  MentiAnimationClip? find(String look, MentiLifeReaction reaction) {
    if (!developerPreview) return null;
    final matches =
        clips.where((c) => c.lookId == look && c.reaction == reaction).toList()
          ..sort((a, b) => b.version.compareTo(a.version));
    return matches.isEmpty ? null : matches.first;
  }
}
