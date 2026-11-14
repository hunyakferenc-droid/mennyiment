import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'app_language.dart';
import 'menti_motion.dart';
import 'menti_collection_model.dart';
import 'menti_collection_store.dart';
import 'menti_collection_widgets.dart';
import 'menti_identity/menti_studio_page.dart';

/// Explicit mode switch; the old profile and new choice are both retained.
Future<void> openLegacyStudio(BuildContext context) async {
  final store = CompleteLookScope.of(context);
  final s = appStrings(context);
  if (store?.ready == true && store!.selection.active) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(s.collectionSwitchLegacyTitle),
        content: Text(s.collectionSwitchLegacyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.avatarCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.collectionSwitchLegacyConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (!await store.save(store.selection.copyWith(active: false))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.completeSaveError)));
      }
      return;
    }
  }
  if (context.mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const MentiStudioPage()),
    );
  }
}

class CollectionLookThumbnail extends StatelessWidget {
  const CollectionLookThumbnail({
    super.key,
    required this.look,
    this.size = 180,
  });
  final CompleteLook look;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: look.thumbnail == null
        ? CompleteLookArtwork(look: look, size: size, background: false)
        : SizedBox(
            width: size,
            height: size * 4 / 3,
            child: Image.asset(
              look.thumbnail!,
              fit: BoxFit.contain,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, 360),
              errorBuilder: (ctx, error, stack) =>
                  Text(appStrings(ctx).completeImageError),
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
  String? _draft, _baseLook;
  bool _baseActive = false, _conflict = false;
  bool _active = false, _leave = false, _asking = false;
  String _family = 'all', _view = 'all';
  bool _preview = true;
  bool get _dirty =>
      _store != null &&
      _draft != null &&
      (_draft != _baseLook || _active != _baseActive);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store ??= widget.store ?? CompleteLookScope.of(context);
    if (_store?.ready == true && _draft == null) {
      _draft = _baseLook = _store!.selection.lookId;
      _active = _baseActive = _store!.selection.active;
    }
  }

  Future<bool> _discard() async {
    if (!_dirty) return true;
    if (_asking) return false;
    _asking = true;
    final s = appStrings(context);
    final answer = await showDialog<bool>(
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
    return answer == true;
  }

  Future<void> _back() async {
    if (_store?.saving == true || !await _discard() || !mounted) return;
    setState(() => _leave = true);
    Navigator.pop(context);
  }

  Future<void> _save() async {
    final store = _store;
    if (store == null || store.saving || _draft == null || _conflict) return;
    final ok = await store.save(
      store.selection.copyWith(active: _active, lookId: _draft),
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

  Future<void> _enlarge(CompleteLook look) async {
    if (_asking) return;
    _asking = true;
    final s = appStrings(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final size = (MediaQuery.sizeOf(ctx).width - 100).clamp(180.0, 640.0);
        return AlertDialog(
          scrollable: true,
          title: Text(look.name(ctx)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size * 4 / 3,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: CompleteLookArtwork(
                    look: look,
                    size: size,
                    decodeScale: 3,
                    background: false,
                  ),
                ),
              ),
              if (look.minXp > 0)
                Text(
                  _store!.owns(look)
                      ? s.collectionOwned
                      : s.collectionRequiredXp(look.minXp),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.avatarClosePreview),
            ),
          ],
        );
      },
    );
    _asking = false;
  }

  Widget _card(CompleteLook look, CompleteLookStore store) {
    final s = appStrings(context),
        owned = store.owns(look),
        selected = _active && _draft == look.id;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label: s.avatarEnlargePreview,
              child: InkWell(
                onTap: () => _enlarge(look),
                child: Center(child: CollectionLookThumbnail(look: look)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              look.name(context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  owned ? Icons.check_circle_outline : Icons.lock_outline,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    look.minXp == 0
                        ? s.collectionStarter
                        : owned
                        ? s.collectionOwned
                        : s.collectionRequiredXp(look.minXp),
                  ),
                ),
              ],
            ),
            if (!owned && look.minXp > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: store.xp == null
                    ? 0
                    : (store.xp! / look.minXp).clamp(0, 1),
              ),
              Text(
                store.xp == null
                    ? s.collectionXpUnavailable
                    : s.collectionXpProgress(
                        store.xp!.clamp(0, look.minXp),
                        look.minXp,
                      ),
              ),
            ],
            const SizedBox(height: 10),
            Semantics(
              identifier: 'collection-select-${look.id}',
              label: look.name(context),
              selected: selected,
              child: FilledButton.tonalIcon(
                key: ValueKey('complete-${look.id}'),
                onPressed: owned && store.ready && !store.saving
                    ? () => setState(() {
                        _draft = look.id;
                        _active = true;
                      })
                    : null,
                icon: Icon(
                  selected
                      ? Icons.check_circle
                      : owned
                      ? Icons.person_outline
                      : Icons.lock_outline,
                ),
                label: Text(
                  selected
                      ? s.collectionSelected
                      : owned
                      ? s.collectionSelect
                      : s.collectionLockedLabel,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _enlarge(look),
              icon: const Icon(Icons.zoom_in),
              label: Text(s.avatarEnlargePreview),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context), store = _store;
    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.collectionTitle)),
        body: Text(s.completeSaveError),
      );
    }
    return ListenableBuilder(
      listenable: store,
      builder: (ctx, _) {
        if (store.ready) {
          final changed =
              _baseLook != null &&
              (_baseLook != store.selection.lookId ||
                  _baseActive != store.selection.active);
          if (changed && _dirty) {
            _conflict = true;
          } else if (_draft == null || changed) {
            _draft = _baseLook = store.selection.lookId;
            _active = _baseActive = store.selection.active;
          }
        }
        final selected =
            CompleteLook.find(
              _draft ?? store.selection.lookId,
              catalog: store.catalog,
            ) ??
            store.catalog.first;
        final filtered = store.catalog
            .where(
              (look) =>
                  (_family == 'all' || look.family == _family) &&
                  (_view == 'all' ||
                      (_view == 'owned'
                          ? store.owns(look)
                          : !store.owns(look))),
            )
            .toList();
        return PopScope(
          canPop: _leave || (!_dirty && !store.saving),
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _back();
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight:
                  56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
              title: Text(s.collectionTitle, maxLines: 2),
              leading: BackButton(onPressed: _back),
              actions: [
                IconButton(
                  tooltip: _preview ? s.avatarHidePreview : s.avatarShowPreview,
                  onPressed: () => setState(() => _preview = !_preview),
                  icon: Icon(
                    _preview
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                minimum: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.collectionCurrentSelection(
                        _active
                            ? selected.name(context)
                            : s.collectionLegacyStudio,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const ValueKey('complete-save'),
                          onPressed: store.ready && !store.saving && !_conflict
                              ? _save
                              : null,
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
                  ],
                ),
              ),
            ),
            body: SafeArea(
              child: CustomScrollView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(200),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(s.collectionIntro),
                          const SizedBox(height: 12),
                          if (_preview) ...[
                            Center(
                              child: AnimatedSwitcher(
                                duration: MentiMotionScope.reducedOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 140),
                                child: CompleteLookArtwork(
                                  key: ValueKey(selected.id),
                                  look: selected,
                                  size: 210,
                                  background: false,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              key: const ValueKey('complete-enlarge'),
                              onPressed: () => _enlarge(selected),
                              icon: const Icon(Icons.zoom_in),
                              label: Text(s.avatarEnlargePreview),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final family in [
                                'all',
                                'boy',
                                'girl',
                                'neutral',
                              ])
                                ChoiceChip(
                                  key: ValueKey('collection-family-$family'),
                                  label: Text(switch (family) {
                                    'boy' => s.collectionBoy,
                                    'girl' => s.collectionGirl,
                                    'neutral' => s.collectionNeutral,
                                    _ => s.collectionAllFamilies,
                                  }),
                                  selected: _family == family,
                                  onSelected: (_) =>
                                      setState(() => _family = family),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final view in ['all', 'owned', 'locked'])
                                ChoiceChip(
                                  key: ValueKey('collection-view-$view'),
                                  label: Text(
                                    view == 'all'
                                        ? s.collectionAll
                                        : view == 'owned'
                                        ? s.collectionOwned
                                        : s.collectionUnlockable,
                                  ),
                                  selected: _view == view,
                                  onSelected: (_) =>
                                      setState(() => _view = view),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.collectionStarterCount(
                              store.catalog.where((l) => l.minXp == 0).length,
                            ),
                          ),
                          if (store.xp == null) Text(s.collectionXpUnavailable),
                          if (store.error != null || _conflict) ...[
                            const SizedBox(height: 12),
                            Text(
                              _conflict
                                  ? s.collectionChanged
                                  : s.completeSaveError,
                            ),
                            TextButton(
                              onPressed: store.saving
                                  ? null
                                  : () async {
                                      await store.load();
                                      if (mounted && store.ready) {
                                        setState(() {
                                          _draft = _baseLook =
                                              store.selection.lookId;
                                          _active = _baseActive =
                                              store.selection.active;
                                          _conflict = false;
                                        });
                                      }
                                    },
                              child: Text(s.restoreRetry),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(s.collectionNoMatches),
                            TextButton(
                              onPressed: () => setState(() {
                                _family = 'all';
                                _view = 'all';
                              }),
                              child: Text(s.collectionResetFilters),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: _card(filtered[index], store),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(s.collectionXpDurableInfo),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('complete-legacy'),
                            onPressed: store.ready && !store.saving
                                ? () => setState(() {
                                    _draft ??= store.selection.lookId;
                                    _active = false;
                                  })
                                : null,
                            icon: Icon(
                              !_active ? Icons.check_circle : Icons.history,
                            ),
                            label: Text(s.collectionUseLegacy),
                          ),
                          TextButton.icon(
                            key: const ValueKey(
                              'collection-open-legacy-studio',
                            ),
                            onPressed: !_dirty && !store.saving
                                ? () => openLegacyStudio(context)
                                : null,
                            icon: const Icon(Icons.tune),
                            label: Text(s.collectionLegacyStudio),
                          ),
                          // Allow the last control to scroll above a visible
                          // unlock/save snackbar, including at large text sizes.
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
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
