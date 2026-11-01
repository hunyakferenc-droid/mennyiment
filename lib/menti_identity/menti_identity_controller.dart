import 'dart:math';

import 'package:flutter/material.dart';

import '../menti_xp_store.dart';
import 'menti_identity.dart';
import 'menti_identity_store.dart';
import 'menti_visual_catalog.dart';
import 'menti_reference_rig.dart';

class MentiIdentityController extends ChangeNotifier {
  MentiIdentityController({MentiIdentityStore? store}) : store = store ?? MentiIdentityStore();
  final MentiIdentityStore store;
  MentiIdentityDocument draft = MentiIdentityDocument(profile: MentiIdentityProfile());
  bool ready = false;
  bool saving = false;
  bool loading = false;
  int level = 1;
  bool xpUnavailable = false;
  String? error;
  bool _disposed = false;
  bool get writable => ready && store.writable && !saving;
  bool get dirty => draft.encode() != store.document.encode();
  MentiIdentityProfile get profile => ready ? store.document.profile : MentiIdentityProfile();
  void _notify() { if (!_disposed) notifyListeners(); }

  Future<void> load() async {
    if (saving || loading || _disposed) return;
    loading = true;
    error = null;
    try {
      await store.load();
      final prefs = await store.open();
      // Pure XP read: opening Studio does not award points or run XP migrations.
      final xpRaw = prefs.get(MentiXpStore.currentKey);
      level = 1;
      xpUnavailable = false;
      if (xpRaw != null) {
        try { level = MentiXpStore.readCurrent(xpRaw).level; }
        on FormatException { xpUnavailable = true; }
      }
      draft = store.document;
      ready = true;
      error = store.error;
    } catch (_) {
      ready = false;
      error = 'load';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> refreshXp() async {
    try {
      final prefs = await store.open();
      await prefs.reload();
      final raw = prefs.get(MentiXpStore.currentKey);
      level = raw == null ? 1 : MentiXpStore.readCurrent(raw).level;
      xpUnavailable = false;
    } catch (_) { level = 1; xpUnavailable = true; }
    _notify();
  }

  Set<String> get effectiveUnlocks => {
    ...draft.unlocks.unlocked,
    for (final o in MentiVisualCatalog.options) if (level >= o.level) o.rewardId,
  };
  bool unlocked(MentiVisualOption o) => effectiveUnlocks.contains(o.rewardId);
  bool newlyAcquired(MentiVisualOption o) => o.level > 1 && unlocked(o) &&
      !draft.unlocks.seen.contains(o.rewardId);
  List<MentiVisualOption> choices(String field) => MentiVisualCatalog.forField(field,
    family: field == 'hair' ? MentiVisualCatalog.resolve('family', draft.profile.visual.value('family')).id : null);

  void choose(MentiVisualOption option) {
    if (!writable || !unlocked(option)) return;
    draft = draft.copyWith(unlocks: draft.unlocks.grant(effectiveUnlocks).acknowledge([option.rewardId]));
    if (option.field == 'reaction') {
      draft = draft.copyWith(profile: draft.profile.copyWith(reaction:
        MentiReactionProfile({...draft.profile.reaction.toJson(), 'style': option.id})));
    } else {
      final changes = {option.field: option.id};
      if (option.field == 'family') {
        changes['hair'] = MentiReferenceRig.of(option.id,
        MentiVisualCatalog.resolve('age', draft.profile.visual.value('age')).id).hairId;
      }
      if (option.field == 'style') {
        final outfit = {'classic': 'basic', 'sporty': 'sport'}[option.id] ?? option.id;
        final coordinated = MentiVisualCatalog.resolve('outfit', outfit);
        if (unlocked(coordinated)) changes['outfit'] = coordinated.id;
      }
      draft = draft.copyWith(profile: draft.profile.copyWith(
        visual: draft.profile.visual.withValues(changes)));
    }
    _notify();
  }
  void rename(String name) {
    if (!writable || name.trim().isEmpty || name.length > 80) return;
    draft = draft.copyWith(profile: draft.profile.copyWith(name: name.trim()));
    _notify();
  }
  void revert() { if (writable) { draft = store.document; _notify(); } }
  void reset() {
    if (!writable) return;
    draft = draft.copyWith(profile: draft.profile.copyWith(
      visual: MentiVisualProfile({...draft.profile.visual.toJson(), ...MentiVisualProfile.defaults}),
      reaction: MentiReactionProfile({...draft.profile.reaction.toJson(), 'style': 'motivating'})));
    _notify();
  }
  void randomize([Random? random]) {
    if (!writable) return;
    final rng = random ?? Random();
    final fields = ['family', ...MentiVisualProfile.defaults.keys.where((f) => f != 'family'), 'reaction'];
    for (final field in fields) {
      final items = choices(field).where(unlocked).toList();
      choose(items[rng.nextInt(items.length)]);
    }
  }
  bool addPreset(String name) {
    if (!writable || draft.presets.length >= 100 || name.trim().isEmpty || name.length > 80) return false;
    var id = 'preset-${DateTime.now().microsecondsSinceEpoch}';
    while (draft.presets.any((p) => p.id == id)) { id += '-copy'; }
    draft = draft.copyWith(presets: [...draft.presets,
      MentiPreset(id: id, name: name.trim(), profile: draft.profile)]);
    _notify();
    return true;
  }
  void applyPreset(MentiPreset preset) {
    if (!writable) return;
    // Existing/legacy identities keep their equipment. Imported presets cannot
    // equip newly locked items; already equipped grandfathered items are allowed.
    for (final field in [...MentiVisualProfile.defaults.keys, 'reaction']) {
      final id = field == 'reaction' ? preset.profile.reaction.style : preset.profile.visual.value(field);
      final o = MentiVisualCatalog.resolve(field, id);
      final current = field == 'reaction' ? draft.profile.reaction.style : draft.profile.visual.value(field);
      if (o.id == id && !unlocked(o) && current != id) return;
    }
    draft = draft.copyWith(profile: preset.profile);
    _notify();
  }
  void favorite(MentiPreset preset) {
    if (!writable) return;
    draft = draft.copyWith(presets: [for (final p in draft.presets)
      p.id == preset.id ? p.copyWith(favorite: !p.favorite) : p]);
    _notify();
  }
  void duplicate(MentiPreset preset, String name) {
    if (!writable || draft.presets.length >= 100 || name.trim().isEmpty || name.length > 80) return;
    var id = '${preset.id}-copy';
    while (draft.presets.any((p) => p.id == id)) { id += '-copy'; }
    if (id.length > 80) id = 'copy-${DateTime.now().microsecondsSinceEpoch}';
    draft = draft.copyWith(presets: [...draft.presets, preset.copyWith(id: id, name: name.trim())]);
    _notify();
  }
  Future<bool> save() async {
    if (!writable) return false;
    saving = true; error = null; _notify();
    final next = draft.copyWith(unlocks: draft.unlocks.grant(effectiveUnlocks));
    final ok = await store.save(next);
    if (ok) { draft = store.document; } else { error = store.error ?? 'save'; }
    saving = false; _notify();
    return ok;
  }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}

/// The application mounts this after BackupRestorer.recover, keyed by restore epoch.
class MentiIdentityScope extends StatefulWidget {
  const MentiIdentityScope({super.key, required this.child, this.controller});
  final Widget child;
  final MentiIdentityController? controller;
  static MentiIdentityController? of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_IdentityInherited>()?.notifier;
  @override
  State<MentiIdentityScope> createState() => _MentiIdentityScopeState();
}
class _MentiIdentityScopeState extends State<MentiIdentityScope> {
  late final controller = widget.controller ?? MentiIdentityController();
  @override
  void initState() { super.initState(); controller.load(); }
  @override
  void dispose() { if (widget.controller == null) controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _IdentityInherited(notifier: controller, child: widget.child);
}
class _IdentityInherited extends InheritedNotifier<MentiIdentityController> {
  const _IdentityInherited({required super.notifier, required super.child});
}
