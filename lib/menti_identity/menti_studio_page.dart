import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_language.dart';
import '../menti_motion.dart';
import '../l10n/generated/app_localizations.dart';
import 'menti_avatar_renderer.dart';
import 'menti_identity_controller.dart';

class MentiStudioPage extends StatefulWidget {
  const MentiStudioPage({super.key, this.controller});
  final MentiIdentityController? controller;
  @override
  State<MentiStudioPage> createState() => _MentiStudioPageState();
}
class _MentiStudioPageState extends State<MentiStudioPage> {
  MentiIdentityController? _controller;
  bool _owned = false;
  bool _leave = false;
  int _tab = 0;
  static const _sections = [
    ['family', 'age', 'style'], ['face', 'eyes', 'hair', 'headwear'],
    ['outfit', 'accent'], ['glasses', 'neck', 'held', 'detail', 'back'],
    ['background', 'aura', 'reaction'], <String>[],
  ];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _controller = widget.controller ?? MentiIdentityScope.of(context);
    _owned = _controller == null;
    _controller ??= MentiIdentityController();
    if (!_controller!.ready) { _controller!.load(); }
    else { _controller!.refreshXp(); }
  }
  @override
  void dispose() { if (_owned) _controller?.dispose(); super.dispose(); }

  Future<void> _save() async {
    final ok = await _controller!.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
      Text(ok ? appStrings(context).avatarSaved : appStrings(context).avatarSaveError)));
  }
  Future<String?> _askName({String? initial}) async {
    final input = TextEditingController(text: initial);
    final s = appStrings(context);
    final route = DialogRoute<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(s.avatarPresetName),
      content: TextField(key: const ValueKey('preset-name'), controller: input,
        maxLength: 80, autofocus: true, decoration: InputDecoration(labelText: s.avatarPresetName)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.avatarCancel)),
        FilledButton(onPressed: () { if (input.text.trim().isNotEmpty) { Navigator.pop(ctx, input.text.trim()); } }, child: Text(s.avatarSave))]));
    final result = await Navigator.of(context).push(route);
    await route.completed;
    input.dispose();
    return result;
  }
  Future<void> _preset() async {
    final name = await _askName();
    if (name == null || !mounted) return;
    if (_controller!.addPreset(name)) await _save();
  }
  Future<void> _rename() async {
    final name = await _askName(initial: _controller!.draft.profile.name);
    if (name != null && mounted) _controller!.rename(name);
  }
  Future<void> _back() async {
    if (_controller!.saving) return;
    if (_controller!.dirty) {
      final s = appStrings(context);
      final discard = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(s.avatarUnsaved), content: Text(s.avatarUnsavedBody), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.avatarCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.avatarDiscard))]));
      if (discard != true || !mounted) return;
      _controller!.revert();
    }
    if (!mounted) return;
    setState(() => _leave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.pop(context); });
  }

  String _fieldLabel(AppLocalizations s, String field) => switch (field) {
    'family' => s.avatarFieldFamily, 'age' => s.avatarFieldAge, 'style' => s.avatarFieldStyle,
    'face' => s.avatarFieldFace, 'eyes' => s.avatarFieldEyes, 'hair' => s.avatarFieldHair,
    'headwear' => s.avatarFieldHeadwear, 'outfit' => s.avatarFieldOutfit,
    'accent' => s.avatarFieldAccent, 'glasses' => s.avatarFieldGlasses,
    'neck' => s.avatarFieldNeck, 'held' => s.avatarFieldHeld, 'detail' => s.avatarFieldDetail,
    'back' => s.avatarFieldBack, 'background' => s.avatarFieldBackground,
    'aura' => s.avatarFieldAura, _ => s.avatarFieldReaction,
  };
  Widget _choices(String field, AppLocalizations s) {
    final c = _controller!;
    final selected = field == 'reaction' ? c.draft.profile.reaction.style : c.draft.profile.visual.value(field);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Text(_fieldLabel(s, field), style: Theme.of(context).textTheme.titleMedium)),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        key: ValueKey('choices-$field'), padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final o in c.choices(field)) Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
            child: SizedBox(width: 132, child: Semantics(selected: selected == o.id,
              child: Card(clipBehavior: Clip.antiAlias, color: selected == o.id
                ? Theme.of(context).colorScheme.secondaryContainer : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: selected == o.id ? const Color(0xFFB58BE6) : Colors.transparent, width: 2)),
                child: InkWell(key: ValueKey('option-$field-${o.id}'),
                  onTap: c.writable && c.unlocked(o) ? () => c.choose(o) : null,
                  child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                    MentiPreviewRenderer(option: o, size: 86), const SizedBox(height: 6),
                    Text(o.label(s), textAlign: TextAlign.center), const SizedBox(height: 4),
                    Text(!c.unlocked(o) ? s.avatarLocked(o.level) : o.level == 1 ? s.avatarDefault
                        : c.newlyAcquired(o) ? s.avatarNew : s.avatarUnlocked,
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
                    if (selected == o.id) const Icon(Icons.check_circle_outline, size: 20),
                  ]))),
              )))),
        ])),
    ]);
  }
  Widget _presets(AppLocalizations s) {
    final c = _controller!;
    return Padding(padding: const EdgeInsets.all(18), child: Column(children: [
      FilledButton.tonalIcon(key: const ValueKey('add-preset'), onPressed: c.writable && c.draft.presets.length < 100 ? _preset : null,
        icon: const Icon(Icons.bookmark_add_outlined), label: Text(s.avatarAddPreset)),
      const SizedBox(height: 12),
      if (c.draft.presets.isEmpty) Text(s.avatarNoPresets),
      for (final preset in c.draft.presets) Card(child: Padding(padding: const EdgeInsets.all(12),
        child: Column(children: [
          MentiAvatarRenderer(profile: preset.profile, size: 96),
          Text(preset.name, style: Theme.of(context).textTheme.titleMedium),
          Wrap(alignment: WrapAlignment.center, children: [
            TextButton(onPressed: c.writable ? () => c.applyPreset(preset) : null, child: Text(s.avatarApply)),
            IconButton(tooltip: s.avatarFavorite, onPressed: c.writable ? () => c.favorite(preset) : null,
              icon: Icon(preset.favorite ? Icons.favorite : Icons.favorite_border)),
            IconButton(tooltip: s.avatarDuplicate, onPressed: c.writable && c.draft.presets.length < 100 ? () async {
              final name = await _askName(initial: preset.name);
              if (name != null && mounted) c.duplicate(preset, name);
            } : null, icon: const Icon(Icons.copy_outlined)),
          ]),
        ]))),
      Text(s.avatarPresetHint),
    ]));
  }
  Widget _editor(AppLocalizations s) => ListView(key: ValueKey('studio-editor-$_tab'), children: [
    if (_tab == 0) const Padding(padding: EdgeInsets.all(18), child: MentiMotionPreference()),
    if (_tab == 5) _presets(s) else ...[for (final f in _sections[_tab]) _choices(f, s)],
    const SizedBox(height: 24),
  ]);
  Widget _preview(AppLocalizations s, double maxWidth, double maxHeight) {
    final c = _controller!;
    final profile = c.draft.profile;
    return SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      MentiAvatarRenderer(key: const ValueKey('studio-live-preview'), profile: profile,
        reaction: profile.reaction.style, size: math.min(250, math.min(maxWidth - 24, maxHeight * .56))),
      TextButton(onPressed: c.writable ? _rename : null, child: Text(profile.name,
        style: Theme.of(context).textTheme.titleLarge)),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
        OutlinedButton.icon(key: const ValueKey('studio-random'), onPressed: c.writable ? c.randomize : null,
          icon: const Icon(Icons.shuffle), label: Text(s.avatarRandom)),
        TextButton(key: const ValueKey('studio-revert'), onPressed: c.writable ? c.revert : null, child: Text(s.avatarRevert)),
        TextButton(key: const ValueKey('studio-reset'), onPressed: c.writable ? c.reset : null, child: Text(s.avatarReset)),
      ]),
    ])));
  }
  @override
  Widget build(BuildContext context) {
    final c = _controller!;
    return ListenableBuilder(listenable: c, builder: (context, _) {
      final s = appStrings(context);
      final tabs = [s.avatarTabBasics,s.avatarTabFace,s.avatarTabOutfit,s.avatarTabAccessories,s.avatarTabAtmosphere,s.avatarTabPresets];
      return PopScope(canPop: _leave || (!c.dirty && !c.saving),
        onPopInvokedWithResult: (didPop, result) { if (!didPop) _back(); },
        child: Scaffold(appBar: AppBar(title: Text(s.avatarStudio), actions: [
          TextButton(key: const ValueKey('studio-save'), onPressed: c.writable ? _save : null,
            child: Text(c.saving ? s.avatarSaving : s.avatarSave)),
        ]), body: SafeArea(child: !c.ready ? Center(child: c.error == null
          ? const CircularProgressIndicator() : TextButton(onPressed: c.load, child: Text(s.avatarRetry)))
          : Column(children: [
            if (c.error != null) MaterialBanner(content: Text(s.avatarReadError),
              actions: [TextButton(onPressed: c.saving ? null : c.load, child: Text(s.avatarRetry))]),
            if (c.xpUnavailable) Padding(padding: const EdgeInsets.all(8), child: Text(s.avatarXpUnavailable)),
            SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [for (var i = 0; i < tabs.length; i++) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(
                  key: ValueKey('studio-tab-$i'), label: Text(tabs[i]), selected: _tab == i,
                  onSelected: (_) => setState(() => _tab = i)))])),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              if (wide) { return Row(children: [SizedBox(width: math.min(360, constraints.maxWidth * .4),
                child: _preview(s, math.min(360, constraints.maxWidth * .4), constraints.maxHeight)),
                Expanded(child: _editor(s))]); }
              return Column(children: [SizedBox(height: constraints.maxHeight * .43,
                child: _preview(s, constraints.maxWidth, constraints.maxHeight * .75)),
                Expanded(child: _editor(s))]);
            })),
          ]))));
    });
  }
}
