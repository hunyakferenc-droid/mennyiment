import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
import 'data_backup.dart';
import 'menti_motion.dart';

/// Three real samples only. Unlock metadata is a future extension, not XP logic.
class CompleteLook {
  const CompleteLook(
    this.id,
    this.family,
    this.asset,
    this.sourceSize,
    this.bounds,
  );
  final String id, family, asset;
  final Size sourceSize;
  final Rect bounds;
  String get unlock => 'free';
  String name(BuildContext context) => switch (family) {
    'boy' => appStrings(context).completeBoy,
    'girl' => appStrings(context).completeGirl,
    _ => appStrings(context).completeNeutral,
  };
  static const all = [
    CompleteLook(
      'boy-base-v1',
      'boy',
      'assets/images/menti_complete/boy-base.png',
      Size(1086, 1448),
      Rect.fromLTRB(137, 74, 941, 1390),
    ),
    CompleteLook(
      'girl-base-v1',
      'girl',
      'assets/images/menti_complete/girl-base.png',
      Size(1086, 1448),
      Rect.fromLTRB(90, 0, 1017, 1418),
    ),
    CompleteLook(
      'neutral-base-v1',
      'neutral',
      'assets/images/menti_complete/neutral-base.png',
      Size(1254, 1254),
      Rect.fromLTRB(224, 68, 1001, 1192),
    ),
  ];
  static CompleteLook? find(String? id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class CompleteLookSelection {
  const CompleteLookSelection({
    this.active = false,
    this.lookId = 'boy-base-v1',
  });
  final bool active;
  final String lookId;
  String encode() =>
      jsonEncode({'version': 1, 'active': active, 'look': lookId});
  static CompleteLookSelection decode(Object? raw) {
    if (raw == null) return const CompleteLookSelection();
    if (raw is! String) throw const FormatException('Invalid complete look');
    final data = decodeBackupJson(raw);
    if (data is! Map ||
        data.length != 3 ||
        data['version'] != 1 ||
        data['version'] is! int ||
        data['active'] is! bool ||
        data['look'] is! String ||
        CompleteLook.find(data['look']) == null) {
      throw const FormatException('Unsupported complete look');
    }
    return CompleteLookSelection(
      active: data['active'] as bool,
      lookId: data['look'] as String,
    );
  }
}

/// Own presentation key only. No profile conversion or XP/reward writes.
class CompleteLookStore extends ChangeNotifier {
  CompleteLookStore({Future<SharedPreferences> Function()? open})
    : open = open ?? SharedPreferences.getInstance;
  static const key = 'mennyiment_complete_look_v1';
  static bool _writing = false;
  final Future<SharedPreferences> Function() open;
  CompleteLookSelection selection = const CompleteLookSelection();
  Object? _snapshot;
  bool ready = false, saving = false, loading = false;
  String? error;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (saving || loading || _disposed) return;
    loading = true;
    try {
      final p = await open();
      await p.reload();
      final raw = p.get(key);
      final next = CompleteLookSelection.decode(raw);
      selection = next;
      _snapshot = raw;
      ready = true;
      error = null;
    } catch (_) {
      ready = false;
      error = 'load';
      // Unknown/corrupt storage is never repaired by choosing a fallback.
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> save(CompleteLookSelection next) async {
    if (!ready || loading || saving || _writing || _disposed) return false;
    // Validate before any write, even for programmatic callers.
    try {
      CompleteLookSelection.decode(next.encode());
    } catch (_) {
      return false;
    }
    saving = true;
    _writing = true;
    error = null;
    _notify();
    SharedPreferences? p;
    try {
      p = await open();
      await p.reload();
      if (p.containsKey('__mennyiment_restore_rollback_v1') ||
          p.get(key) != _snapshot) {
        ready = false;
        error = 'conflict';
        return false;
      }
      final raw = next.encode();
      if (_snapshot != raw && !await p.setString(key, raw)) {
        throw StateError('Unconfirmed complete-look write');
      }
      await p.reload();
      if (p.get(key) != raw) {
        ready = false;
        error = 'conflict';
        return false;
      }
      _snapshot = raw;
      selection = next;
      return true;
    } catch (_) {
      error = 'save';
      try {
        await p?.reload();
      } catch (_) {
        ready = false;
      }
      return false;
    } finally {
      saving = false;
      _writing = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class CompleteLookScope extends StatefulWidget {
  const CompleteLookScope({super.key, required this.child, this.store});
  final Widget child;
  final CompleteLookStore? store;
  static CompleteLookStore? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CompleteInherited>()
      ?.notifier;
  @override
  State<CompleteLookScope> createState() => _CompleteLookScopeState();
}

class _CompleteLookScopeState extends State<CompleteLookScope>
    with WidgetsBindingObserver {
  late final store = widget.store ?? CompleteLookStore();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _CompleteInherited(notifier: store, child: widget.child);
}

class _CompleteInherited extends InheritedNotifier<CompleteLookStore> {
  const _CompleteInherited({required super.notifier, required super.child});
}

/// One complete PNG, shared canvas and footline. The environment is separate.
/// No legacy face, clothing, hat or reward overlay enters this renderer.
class CompleteLookArtwork extends StatelessWidget {
  const CompleteLookArtwork({
    super.key,
    required this.look,
    this.size = 260,
    this.background = true,
  });
  final CompleteLook look;
  final double size;
  final bool background;
  static const backgroundColor = Color(0xFFF2EFF6);
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: look.name(context),
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size * 4 / 3,
          child: ColoredBox(
            color: background ? backgroundColor : Colors.transparent,
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale =
                      constraints.maxHeight * .88 / look.bounds.height;
                  final width = look.sourceSize.width * scale;
                  final height = look.sourceSize.height * scale;
                  final cacheWidth =
                      (width * MediaQuery.devicePixelRatioOf(context))
                          .ceil()
                          .clamp(1, look.sourceSize.width.toInt());
                  return Stack(
                    children: [
                      Positioned(
                        left:
                            (constraints.maxWidth - look.bounds.width * scale) /
                                2 -
                            look.bounds.left * scale,
                        top:
                            constraints.maxHeight * .94 -
                            look.bounds.bottom * scale,
                        width: width,
                        height: height,
                        child: Image.asset(
                          look.asset,
                          width: width,
                          height: height,
                          cacheWidth: cacheWidth,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stack) => Center(
                            child: Text(appStrings(context).completeImageError),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class CompleteLooksPage extends StatefulWidget {
  const CompleteLooksPage({super.key, this.store});
  final CompleteLookStore? store;
  @override
  State<CompleteLooksPage> createState() => _CompleteLooksPageState();
}

class _CompleteLooksPageState extends State<CompleteLooksPage> {
  CompleteLookStore? _store;
  String? _draft;
  bool _active = false, _leave = false, _asking = false;
  bool get _dirty =>
      _store != null &&
      _draft != null &&
      (_draft != _store!.selection.lookId ||
          _active != _store!.selection.active);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_store == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      });
    }
    _store ??= widget.store ?? CompleteLookScope.of(context);
    if (_store?.ready == true && _draft == null) {
      _draft = _store!.selection.lookId;
      _active = _store!.selection.active;
    }
  }

  Future<void> _back() async {
    if (_asking || _store?.saving == true) return;
    if (_dirty) {
      _asking = true;
      final s = appStrings(context);
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          scrollable: true,
          title: Text(s.completeDiscard),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.avatarCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.completeLeave),
            ),
          ],
        ),
      );
      _asking = false;
      if (discard != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _leave = true);
    Navigator.pop(context);
  }

  Future<void> _save() async {
    final store = _store;
    if (store == null || store.saving || _draft == null) return;
    final ok = await store.save(
      CompleteLookSelection(active: _active, lookId: _draft!),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? appStrings(context).avatarSaved
              : appStrings(context).completeSaveError,
        ),
      ),
    );
    if (ok) {
      setState(() => _leave = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final store = _store;
    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.completeTitle)),
        body: Text(s.completeSaveError),
      );
    }
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final look = CompleteLook.find(_draft ?? store.selection.lookId)!;
        return PopScope(
          canPop: _leave || (!_dirty && !store.saving),
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _back();
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight:
                  56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
              title: Text(s.completeTitle, maxLines: 2),
              leading: BackButton(onPressed: _back),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(s.completeInfo),
                  const SizedBox(height: 12),
                  Center(
                    child: AnimatedSwitcher(
                      duration: MentiMotionScope.reducedOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 140),
                      child: CompleteLookArtwork(
                        key: ValueKey(look.id),
                        look: look,
                        size: 240,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('complete-enlarge'),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        scrollable: true,
                        title: Text(look.name(context)),
                        content: CompleteLookArtwork(
                          look: look,
                          size: (MediaQuery.sizeOf(ctx).width - 100).clamp(
                            180,
                            640,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(s.avatarClosePreview),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.zoom_in),
                    label: Text(s.avatarEnlargePreview),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    look.name(context),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final item in CompleteLook.all)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        selected: item == look && _active,
                        child: OutlinedButton(
                          key: ValueKey('complete-${item.id}'),
                          onPressed: store.ready && !store.saving
                              ? () => setState(() {
                                  _draft = item.id;
                                  _active = true;
                                })
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CompleteLookArtwork(look: item, size: 64),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item.name(context))),
                                const SizedBox(width: 8),
                                Icon(
                                  item == look && _active
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('complete-legacy'),
                    onPressed: store.ready && !store.saving
                        ? () => setState(() {
                            _draft ??= store.selection.lookId;
                            _active = false;
                          })
                        : null,
                    icon: Icon(!_active ? Icons.check_circle : Icons.history),
                    label: Text(s.completeLegacy),
                  ),
                  if (store.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      s.completeSaveError,
                      semanticsLabel: s.completeSaveError,
                    ),
                    TextButton(
                      onPressed: store.saving
                          ? null
                          : () async {
                              await store.load();
                              if (mounted && store.ready) {
                                setState(() {
                                  _draft = store.selection.lookId;
                                  _active = store.selection.active;
                                });
                              }
                            },
                      child: Text(s.restoreRetry),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('complete-save'),
                    onPressed: store.ready && !store.saving ? _save : null,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(s.avatarSave),
                  ),
                  TextButton(
                    key: const ValueKey('complete-cancel'),
                    onPressed: store.saving ? null : _back,
                    child: Text(s.avatarCancel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
