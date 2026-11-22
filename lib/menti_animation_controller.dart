import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import 'menti_animation_catalog.dart';
import 'menti_life_events.dart';
import 'menti_reaction_engine.dart';

enum MentiPlaybackStatus {
  staticImage,
  loading,
  playing,
  noClip,
  disabled,
  error,
}

abstract class MentiVideoHandle extends ChangeNotifier {
  bool get frameVisible;
  bool get completed;
  bool get failed;
  Widget get view;
  Future<void> initialize();
  Future<void> playMuted();
  Future<void> close();
}

class LocalMentiVideo extends MentiVideoHandle {
  LocalMentiVideo(this.clip)
    : video = VideoPlayerController.asset(
        clip.asset,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
  final MentiAnimationClip clip;
  final VideoPlayerController video;
  bool _closed = false;
  Future<void>? _closing;
  void _changed() {
    if (!_closed) notifyListeners();
  }

  @override
  bool get failed => video.value.hasError;
  @override
  bool get completed => video.value.isCompleted;
  @override
  bool get frameVisible =>
      video.value.isInitialized &&
      video.value.isPlaying &&
      video.value.position > Duration.zero;
  @override
  Widget get view => VideoPlayer(video);
  @override
  Future<void> initialize() async {
    video.addListener(_changed);
    await video.initialize();
    if (_closed) return;
    final v = video.value;
    if ((v.size.width - clip.width).abs() > 1 ||
        (v.size.height - clip.height).abs() > 1 ||
        (v.duration.inMilliseconds - clip.durationMs).abs() > 500) {
      throw StateError('Media does not match review');
    }
    await video.setVolume(0);
    await video.setLooping(false);
  }

  @override
  Future<void> playMuted() async {
    if (!_closed) {
      await video.setVolume(0);
      await video.play();
    }
  }

  @override
  Future<void> close() => _closing ??= _closeOnce();
  Future<void> _closeOnce() async {
    _closed = true;
    video.removeListener(_changed);
    try {
      await video.dispose();
    } finally {
      super.dispose();
    }
  }
}

Future<void> verifyMentiAnimationAsset(MentiAnimationClip clip) async {
  final data = await rootBundle.load(clip.asset);
  if (data.lengthInBytes != clip.bytes ||
      sha256
              .convert(
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              )
              .toString() !=
          clip.sha256) {
    throw StateError('Unreviewed animation bytes');
  }
}

class MentiAnimationController extends ChangeNotifier {
  MentiAnimationController({
    this.catalog = const MentiAnimationCatalog(),
    MentiVideoHandle Function(MentiAnimationClip)? factory,
    Future<void> Function(MentiAnimationClip)? verify,
    DateTime Function()? clock,
  }) : factory = factory ?? LocalMentiVideo.new,
       verify = verify ?? verifyMentiAnimationAsset,
       clock = clock ?? DateTime.now;
  MentiAnimationCatalog catalog;
  void replaceCatalog(MentiAnimationCatalog next) {
    catalog = next;
    stop();
  }

  final MentiVideoHandle Function(MentiAnimationClip) factory;
  final Future<void> Function(MentiAnimationClip) verify;
  final DateTime Function() clock;
  final MentiReactionEngine _engine = MentiReactionEngine();
  static Future<void>? _decoderTail;
  static MentiAnimationController? _decoderOwner;
  Future<void> get settled => _decoderTail ?? Future<void>.value();
  final Map<Object, ({String look, double size})> _hosts = {};
  Object? _host;
  String? lookId;
  bool _allowed = false, _foreground = true, _disposed = false;
  MentiAnimationFrequency frequency = MentiAnimationFrequency.normal;
  MentiPlaybackStatus status = MentiPlaybackStatus.staticImage;
  MentiAnimationClip? active;
  MentiVideoHandle? handle;
  int _generation = 0, _priority = -1;
  Timer? _deadline;
  final List<Map<String, Object>> measurements = [];
  bool _notificationPending = false;
  bool get animationAllowed => _allowed && _foreground;
  bool get hasVisibleHost => _host != null && _allowed && _foreground;
  void _notify() {
    if (_disposed) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (!_notificationPending) {
        _notificationPending = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notificationPending = false;
          _notify();
        });
      }
      return;
    }
    notifyListeners();
  }

  void configure({
    required String? look,
    required bool allowed,
    required MentiAnimationFrequency frequency,
  }) {
    final changed = lookId != look || _allowed != allowed;
    lookId = look;
    _allowed = allowed;
    this.frequency = frequency;
    if (changed) {
      stop(
        reason: allowed
            ? MentiPlaybackStatus.staticImage
            : MentiPlaybackStatus.disabled,
      );
      _elect();
    }
  }

  void foreground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    if (!value) stop();
  }

  void host(
    Object id, {
    required String look,
    required double size,
    required bool visible,
  }) {
    if (_disposed) return;
    if (visible) {
      _hosts[id] = (look: look, size: size);
    } else {
      _hosts.remove(id);
    }
    _elect();
  }

  void removeHost(Object id) {
    _hosts.remove(id);
    _elect();
  }

  void _elect() {
    Object? next;
    var size = -1.0;
    for (final entry in _hosts.entries) {
      if (entry.value.look == lookId && entry.value.size > size) {
        next = entry.key;
        size = entry.value.size;
      }
    }
    if (next != _host) {
      _host = next;
      stop(
        reason: _allowed
            ? MentiPlaybackStatus.staticImage
            : MentiPlaybackStatus.disabled,
      );
    }
  }

  bool owns(Object id) => _host == id && active != null;
  bool react(MentiLifeSignal signal, {bool manual = false}) {
    final p = MentiReactionEngine.plan(signal.event);
    return request(
      p.reaction,
      token: '${signal.event.name}:${signal.token}',
      priority: p.priority,
      manual: manual,
    );
  }

  bool request(
    MentiLifeReaction reaction, {
    required String token,
    int priority = 100,
    bool manual = false,
  }) {
    if (_disposed ||
        !_allowed ||
        !_foreground ||
        _host == null ||
        lookId == null) {
      return false;
    }
    if (active != null && !manual && priority < _priority) return false;
    final clip = catalog.find(lookId!, reaction);
    if (clip == null) {
      stop(reason: MentiPlaybackStatus.noClip);
      return false;
    }
    if (active?.id == clip.id) return false;
    if (!_engine.accept(
      token,
      clock(),
      frequency,
      manual: manual,
      urgent: active != null && priority > _priority,
    )) {
      return false;
    }
    _generation++;
    final generation = _generation;
    _deadline?.cancel();
    active = clip;
    _priority = priority;
    status = MentiPlaybackStatus.loading;
    _notify();
    _enqueue(() async {
      if (!_valid(generation)) return;
      final previous = _decoderOwner;
      if (previous != null && previous != this) {
        previous._invalidate();
        await previous._closeHandle();
      }
      await _closeHandle();
      if (!_valid(generation)) return;
      _decoderOwner = this;
      final watch = Stopwatch()..start();
      try {
        await verify(clip).timeout(const Duration(seconds: 4));
        if (!_valid(generation)) return;
        final media = factory(clip);
        handle = media;
        await media.initialize().timeout(const Duration(seconds: 4));
        if (!_valid(generation)) {
          await _closeHandle();
          return;
        }
        var visibleFrame = false;
        void changed() {
          if (!_valid(generation)) return;
          if (media.failed) {
            stop(reason: MentiPlaybackStatus.error);
          } else if (media.completed) {
            stop();
          } else if (visibleFrame != media.frameVisible) {
            visibleFrame = media.frameVisible;
            _notify();
          }
        }

        media.addListener(changed);
        await media.playMuted().timeout(const Duration(seconds: 2));
        if (!_valid(generation)) {
          await _closeHandle();
          return;
        }
        status = MentiPlaybackStatus.playing;
        measurements.add({
          'clip': clip.id,
          'bytes': clip.bytes,
          'initializeMs': watch.elapsedMilliseconds,
          'estimatedFrameRgbaBytes': clip.width * clip.height * 4,
        });
        if (measurements.length > 20) measurements.removeAt(0);
        _deadline = Timer(
          Duration(milliseconds: clip.durationMs + 1000),
          () => stop(),
        );
        _notify();
      } catch (_) {
        if (_valid(generation)) {
          _invalidate();
          status = MentiPlaybackStatus.error;
          _notify();
        }
        await _closeHandle();
      }
    });
    return true;
  }

  /// Explicit restart waits for the old decoder to close. A newer selection,
  /// stop, policy or lifecycle change cancels the pending restart.
  Future<bool> restart(
    MentiLifeReaction reaction, {
    required String token,
  }) async {
    if (_disposed) return false;
    stop();
    final generation = _generation;
    await settled;
    if (_disposed || generation != _generation) return false;
    return request(reaction, token: token, manual: true);
  }

  bool _valid(int generation) =>
      !_disposed &&
      generation == _generation &&
      _allowed &&
      _foreground &&
      _host != null &&
      active != null;
  void _enqueue(Future<void> Function() work) {
    final next = (_decoderTail ?? Future<void>.value())
        .catchError((Object _) {})
        .then((_) => work())
        .catchError((Object _) {
          if (!_disposed) {
            _invalidate();
            status = MentiPlaybackStatus.error;
            _notify();
          }
        });
    _decoderTail = next;
    // Do not retain a completed future (or its old Zone) between sessions.
    next.whenComplete(() {
      if (identical(_decoderTail, next)) _decoderTail = null;
    });
  }

  void _invalidate() {
    _generation++;
    _deadline?.cancel();
    _deadline = null;
    active = null;
    _priority = -1;
    status = MentiPlaybackStatus.staticImage;
    _notify();
  }

  void stop({MentiPlaybackStatus reason = MentiPlaybackStatus.staticImage}) {
    _invalidate();
    status = reason;
    if (handle != null || identical(_decoderOwner, this)) {
      _enqueue(() async {
        if (active == null) await _closeHandle();
      });
    }
    _notify();
  }

  Future<void> _closeHandle() async {
    final media = handle;
    handle = null;
    if (media != null) {
      try {
        await media.close();
      } catch (_) {
        handle = media;
        rethrow;
      }
    }
    if (identical(_decoderOwner, this)) _decoderOwner = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _invalidate();
    _hosts.clear();
    if (handle != null || identical(_decoderOwner, this)) {
      _enqueue(_closeHandle);
    }
    super.dispose();
  }
}
